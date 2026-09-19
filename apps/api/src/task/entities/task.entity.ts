import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  ManyToMany,
  JoinColumn,
  JoinTable,
  Index,
} from 'typeorm';

import { Project } from '../../project/entities/project.entity';
import { User } from '../../user/entities/user.entity';
import { Contact } from '../../contact/entities/contact.entity';

export enum TaskStatus {
  ACTIVE = 'active',
  NEXT_UP = 'next up',
  FUTURE = 'future',
  PAUSED = 'paused',
  STUCK = 'stuck',
  COMPLETED = 'completed',
}

@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  // Task basics

  @Column()
  name!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  // Deliberately a plain varchar, NOT a Postgres native enum. TaskStatus is
  // enforced at the application layer (DTO @IsEnum validation) instead.
  // A DB-level enum here caused repeated data loss during vocabulary
  // changes — synchronize can't safely alter an enum's value list, and any
  // workaround that converts the column to text and back triggers a
  // DROP/ADD COLUMN that silently resets every row to the default value.
  // varchar sidesteps that risk entirely; see project.entity.ts for the
  // matching reasoning on ProjectStatus.
  @Column({ type: 'varchar', default: TaskStatus.FUTURE })
  status!: TaskStatus;

  // Foreign key scalar columns for easy serialization & UI payloads
  @Column({ type: 'uuid' })
  projectId!: string;

  @Index()
  @ManyToOne(() => Project, (project) => project.tasks, {
    nullable: false,
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'projectId' })
  project!: Project;

  @Column({ type: 'date', nullable: true })
  startDate!: Date | null;

  @Column({ type: 'date', nullable: true })
  dueDate!: Date | null;

  @Column({ type: 'int', nullable: true })
  expectedDuration!: number | null;

  // Who this task is assigned to. assigneeName is the raw name as parsed
  // (e.g. from a meeting transcript) and is always kept even when neither
  // FK below could be resolved — a Task can be assigned to internal staff
  // (User) or an external client/lead contact (Contact), never both.
  @Column({ type: 'varchar', nullable: true })
  assigneeName!: string | null;

  @Column({ type: 'uuid', nullable: true })
  assigneeUserId!: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'assigneeUserId' })
  assigneeUser!: User | null;

  @Column({ type: 'uuid', nullable: true })
  assigneeContactId!: string | null;

  @ManyToOne(() => Contact, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'assigneeContactId' })
  assigneeContact!: Contact | null;

  // Recurring task fields
  @Column({ type: 'boolean', default: false })
  isRecurring!: boolean;

  @Column({ type: 'varchar', nullable: true })
  recurrencePattern!: string | null; // 'daily', 'weekly', 'monthly', 'yearly'

  @Column({ type: 'int', nullable: true })
  recurrenceInterval!: number | null; // every X days/weeks/months

  @Column({ type: 'int', nullable: true })
  recurrenceDayOfWeek!: number | null; // 0-6 for Sunday-Saturday (for weekly tasks)

  @Column({ type: 'date', nullable: true })
  recurrenceEndDate!: Date | null;

  @Column({ type: 'int', nullable: true })
  recurrenceCount!: number | null; // null for indefinite

  @Column({ type: 'uuid', nullable: true })
  recurringGroupId!: string | null; // links related recurring tasks

  // Tasks that must be completed before this one. Directional: this task
  // is the "dependent" side, and owns the join table. Reading a.dependsOn
  // gives the tasks a depends on; dependentTasks is the inverse lookup.
  @ManyToMany(() => Task, (task) => task.dependentTasks, {
    onDelete: 'CASCADE',
  })
  @JoinTable({
    name: 'task_dependencies',
    joinColumn: { name: 'taskId' },
    inverseJoinColumn: { name: 'dependsOnTaskId' },
  })
  dependsOn!: Task[];

  @ManyToMany(() => Task, (task) => task.dependsOn)
  dependentTasks!: Task[];

  @Column({ type: 'uuid' })
  createdById!: string;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'createdById' })
  createdBy!: User;

  @Column({ type: 'uuid', nullable: true })
  lastModifiedById!: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'lastModifiedById' })
  lastModifiedBy!: User | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt!: Date | null;
}
