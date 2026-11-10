import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Habit } from '../entities/habit.entity';
import { HabitLog } from '../entities/habit-log.entity';
import { CreateHabitDto, UpdateHabitDto, CreateLogDto } from './dto/habit.dto';

@Injectable()
export class HabitsService {
  constructor(
    @InjectRepository(Habit) private habitRepo: Repository<Habit>,
    @InjectRepository(HabitLog) private logRepo: Repository<HabitLog>,
  ) {}

  async getHabits(userId: string) {
    return this.habitRepo.find({ where: { user_id: userId, is_archived: false }, order: { created_at: 'DESC' } });
  }

  async createHabit(userId: string, dto: CreateHabitDto, isPremium: boolean) {
    const count = await this.habitRepo.count({ where: { user_id: userId, is_archived: false } });
    if (!isPremium && count >= 5) {
      throw new ForbiddenException('Limite de 5 hábitos no plano Free. Assine o Premium para ilimitado.');
    }
    const habit = this.habitRepo.create({ ...dto, user_id: userId });
    return this.habitRepo.save(habit);
  }

  async updateHabit(userId: string, id: string, dto: UpdateHabitDto) {
    const habit = await this.habitRepo.findOne({ where: { id, user_id: userId } });
    if (!habit) throw new NotFoundException('Hábito não encontrado');
    Object.assign(habit, dto);
    return this.habitRepo.save(habit);
  }

  async deleteHabit(userId: string, id: string) {
    const result = await this.habitRepo.delete({ id, user_id: userId });
    if (result.affected === 0) throw new NotFoundException('Hábito não encontrado');
    return { success: true };
  }

  async getLogs(userId: string, from?: string, to?: string) {
    const qb = this.logRepo.createQueryBuilder('log')
      .where('log.user_id = :userId', { userId });
    if (from) qb.andWhere('log.date >= :from', { from });
    if (to) qb.andWhere('log.date <= :to', { to });
    return qb.orderBy('log.date', 'DESC').getMany();
  }

  async createOrUpdateLog(userId: string, dto: CreateLogDto) {
    const habit = await this.habitRepo.findOne({ where: { id: dto.habit_id, user_id: userId } });
    if (!habit) throw new NotFoundException('Hábito não encontrado');

    const logDate = new Date(dto.date);
    let log = await this.logRepo.findOne({ where: { habit_id: dto.habit_id, date: logDate } });
    if (log) {
      log.completed = dto.completed ?? true;
      log.note = dto.note;
    } else {
      log = this.logRepo.create({ ...dto, date: logDate, user_id: userId });
    }
    return this.logRepo.save(log);
  }
}
