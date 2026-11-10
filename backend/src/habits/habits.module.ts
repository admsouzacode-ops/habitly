import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HabitsService } from './habits.service';
import { HabitsController } from './habits.controller';
import { Habit } from '../entities/habit.entity';
import { HabitLog } from '../entities/habit-log.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Habit, HabitLog])],
  providers: [HabitsService],
  controllers: [HabitsController],
})
export class HabitsModule {}
