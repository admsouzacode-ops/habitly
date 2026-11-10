package br.com.souzacode.habitly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget "Hábitos de hoje". Os dados vêm do Dart (lib/services/home_widget_service.dart)
 * via SharedPreferences do home_widget. Tocar no ✓/+ chama o Dart em segundo plano
 * (habitly://toggle?id=N / habitly://plus?id=N), que grava no banco e redesenha.
 */
class HabitlyWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val date = widgetData.getString("date", null)
    val stale = date != null && date != today()
    // Virou o dia (alarme da meia-noite ou atualização periódica): pede ao
    // Dart para recalcular os hábitos de hoje.
    if (stale) requestRefresh(context)
    for (id in appWidgetIds) {
      appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, stale))
    }
  }

  companion object {
    private const val MAX_ROWS = 5
    private const val NATIVE_PREFS = "habitly_widget_native"
    private const val LAST_REFRESH = "last_refresh_request"

    private val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3, R.id.row4)
    private val rowTextIds =
        intArrayOf(R.id.row0_text, R.id.row1_text, R.id.row2_text, R.id.row3_text, R.id.row4_text)
    private val titleIds = intArrayOf(R.id.title0, R.id.title1, R.id.title2, R.id.title3, R.id.title4)
    private val progressIds =
        intArrayOf(R.id.progress0, R.id.progress1, R.id.progress2, R.id.progress3, R.id.progress4)
    private val checkIds = intArrayOf(R.id.check0, R.id.check1, R.id.check2, R.id.check3, R.id.check4)
    private val plusIds = intArrayOf(R.id.plus0, R.id.plus1, R.id.plus2, R.id.plus3, R.id.plus4)

    fun today(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    private fun requestRefresh(context: Context) {
      val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
      val now = System.currentTimeMillis()
      if (now - prefs.getLong(LAST_REFRESH, 0L) < 60_000L) return
      prefs.edit().putLong(LAST_REFRESH, now).apply()
      try {
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("habitly://refresh")).send()
      } catch (_: Exception) {
        // Sem callback registrado ainda (app nunca aberto): fica com os dados atuais.
      }
    }

    fun buildViews(context: Context, data: SharedPreferences, stale: Boolean): RemoteViews {
      val views = RemoteViews(context.packageName, R.layout.habitly_widget)
      val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
      views.setOnClickPendingIntent(R.id.widget_root, open)
      views.setOnClickPendingIntent(R.id.widget_header, open)

      val hasData = data.getString("date", null) != null
      val count = if (stale) 0 else data.getInt("count", 0).coerceIn(0, MAX_ROWS)
      views.setTextViewText(
          R.id.header,
          if (stale) "Atualizando…" else data.getString("header", "Hoje") ?: "Hoje",
      )

      for (i in 0 until MAX_ROWS) {
        if (i >= count) {
          views.setViewVisibility(rowIds[i], View.GONE)
          continue
        }
        val habitId = data.getInt("h${i}_id", -1)
        val done = data.getBoolean("h${i}_done", false)
        val action = data.getString("h${i}_action", "toggle")
        val label = data.getString("h${i}_label", "") ?: ""
        views.setViewVisibility(rowIds[i], View.VISIBLE)
        views.setTextViewText(titleIds[i], data.getString("h${i}_title", "") ?: "")
        views.setTextColor(titleIds[i], if (done) 0xFF7A867E.toInt() else 0xFF1C1B1F.toInt())
        val progress = data.getString("h${i}_progress", "") ?: ""
        views.setTextViewText(progressIds[i], progress)
        views.setViewVisibility(progressIds[i], if (progress.isEmpty()) View.GONE else View.VISIBLE)
        views.setOnClickPendingIntent(rowTextIds[i], open)

        if (action == "plus") {
          views.setViewVisibility(checkIds[i], View.GONE)
          views.setViewVisibility(plusIds[i], View.VISIBLE)
          views.setTextViewText(plusIds[i], label)
          views.setInt(
              plusIds[i],
              "setBackgroundResource",
              if (done) R.drawable.widget_plus_done_bg else R.drawable.widget_plus_bg,
          )
          views.setTextColor(plusIds[i], if (done) 0xFFFFFFFF.toInt() else 0xFF1B7A4B.toInt())
          views.setOnClickPendingIntent(
              plusIds[i],
              HomeWidgetBackgroundIntent.getBroadcast(
                  context,
                  Uri.parse("habitly://plus?id=$habitId"),
              ),
          )
        } else {
          views.setViewVisibility(plusIds[i], View.GONE)
          views.setViewVisibility(checkIds[i], View.VISIBLE)
          views.setTextViewText(checkIds[i], if (done) "✓" else "")
          views.setInt(
              checkIds[i],
              "setBackgroundResource",
              if (done) R.drawable.widget_check_on else R.drawable.widget_check_off,
          )
          views.setOnClickPendingIntent(
              checkIds[i],
              HomeWidgetBackgroundIntent.getBroadcast(
                  context,
                  Uri.parse("habitly://toggle?id=$habitId"),
              ),
          )
        }
      }

      val empty =
          when {
            stale -> "Carregando os hábitos de hoje…"
            !hasData -> "Abra o Habitly para começar"
            else -> data.getString("empty", "") ?: ""
          }
      views.setTextViewText(R.id.empty, empty)
      views.setViewVisibility(R.id.empty, if (count == 0) View.VISIBLE else View.GONE)

      val extra = if (stale) 0 else data.getInt("extra", 0)
      views.setTextViewText(R.id.footer, "+$extra no app")
      views.setViewVisibility(R.id.footer, if (extra > 0) View.VISIBLE else View.GONE)
      views.setOnClickPendingIntent(R.id.footer, open)
      return views
    }
  }
}
