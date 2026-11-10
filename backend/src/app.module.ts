import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { HabitsModule } from './habits/habits.module';
import { User } from './entities/user.entity';
import { Habit } from './entities/habit.entity';
import { HabitLog } from './entities/habit-log.entity';
import { Subscription } from './entities/subscription.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      username: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'habitly',
      entities: [User, Habit, HabitLog, Subscription],
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    AuthModule,
    HabitsModule,
  ],
})
export class AppModule {}
