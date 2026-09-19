import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Client } from '../../client/entities/client.entity';
import { Lead } from '../../lead/entities/lead.entity';

@Entity('attachments')
export class Attachment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  filename!: string;

  @Column()
  url!: string;

  @ManyToOne(() => Client, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'clientId' })
  client?: Client;

  @Column({ type: 'uuid', nullable: true })
  clientId?: string;

  @ManyToOne(() => Lead, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'leadId' })
  lead?: Lead;

  @Column({ type: 'uuid', nullable: true })
  leadId?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;
}
