import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
} from 'typeorm';

import { Client } from '../../client/entities/client.entity';
import { Lead } from '../../lead/entities/lead.entity';
import { User } from '../../user/entities/user.entity';
import { Task } from '../../tasks/entities/task.entity';

export enum ProjectStatus {
  FUTURE = 'future',
  PLANNING = 'planning',
  ACTIVE = 'active',
  ON_HOLD = 'on_hold',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

@Entity('projects')
export class Project {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  // Project basics

  @Column()
  name!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  // Deliberately a plain varchar, NOT a Postgres native enum — see the
  // matching comment on Task.status in task.entity.ts for the full
  // reasoning. ProjectStatus is enforced at the application layer only.
  @Column({ type: 'varchar', default: ProjectStatus.FUTURE })
  status!: ProjectStatus;

  @Column({ type: 'date', nullable: true })
  startDate!: Date | null;

  @Column({ type: 'date', nullable: true })
  dueDate!: Date | null;

  @Column({ type: 'int', nullable: true })
  expectedDuration!: number | null;

  @Column({ type: 'timestamptz', nullable: true })
  completedDate!: Date | null;

  // Foreign key scalar columns for easy serialization & UI payloads
  @Column({ type: 'uuid' })
  createdById!: string;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'createdById' })
  createdBy!: User;

  @Column({ type: 'uuid', nullable: true })
  clientId!: string | null;

  @Index()
  @ManyToOne(() => Client, (client) => client.projects, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'clientId' })
  client!: Client | null;

  @Column({ type: 'uuid', nullable: true })
  leadId!: string | null;

  @Index()
  @ManyToOne(() => Lead, (lead) => lead.projects, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'leadId' })
  lead!: Lead | null;

  @Column({ type: 'uuid', nullable: true })
  lastModifiedById!: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'lastModifiedById' })
  lastModifiedBy!: User | null;

  @OneToMany(() => Task, (task) => task.project)
  tasks!: Task[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;
}
