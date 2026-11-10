import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { HabitsService } from './habits.service';
import { CreateHabitDto, UpdateHabitDto, CreateLogDto } from './dto/habit.dto';

@Controller('habits')
@UseGuards(AuthGuard('jwt'))
export class HabitsController {
  constructor(private habitsService: HabitsService) {}

  @Get()
  getHabits(@Request() req) {
    return this.habitsService.getHabits(req.user.id);
  }

  @Post()
  createHabit(@Request() req, @Body() dto: CreateHabitDto) {
    return this.habitsService.createHabit(req.user.id, dto, req.user.is_premium);
  }

  @Put(':id')
  updateHabit(@Request() req, @Param('id') id: string, @Body() dto: UpdateHabitDto) {
    return this.habitsService.updateHabit(req.user.id, id, dto);
  }

  @Delete(':id')
  deleteHabit(@Request() req, @Param('id') id: string) {
    return this.habitsService.deleteHabit(req.user.id, id);
  }

  @Get('logs')
  getLogs(@Request() req, @Query('from') from?: string, @Query('to') to?: string) {
    return this.habitsService.getLogs(req.user.id, from, to);
  }

  @Post('logs')
  createLog(@Request() req, @Body() dto: CreateLogDto) {
    return this.habitsService.createOrUpdateLog(req.user.id, dto);
  }
}
