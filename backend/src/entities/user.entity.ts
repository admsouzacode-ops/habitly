import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Habit } from './habit.entity';
import { Subscription } from './subscription.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password_hash: string;

  @Column({ nullable: true })
  name: string;

  @Column({ default: false })
  is_premium: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  premium_expires_at: Date;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @OneToMany(() => Habit, habit => habit.user)
  habits: Habit[];

  @OneToMany(() => Subscription, sub => sub.user)
  subscriptions: Subscription[];
}
