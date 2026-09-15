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

@Entity()
export class Contact {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  name!: string;

  @Column()
  email!: string;

  @Column({ nullable: true })
  phone?: string;

  @Column({ nullable: true })
  role?: string;

  @Column({ default: false })
  isPrimary!: boolean;

  @ManyToOne(() => Client, (client) => client.contacts, {
    onDelete: 'CASCADE',
    nullable: true,
  })
  @JoinColumn({ name: 'clientId' })
  client?: Client;

  @Column({ nullable: true })
  clientId?: string;

  @ManyToOne(() => Lead, (lead) => lead.contacts, {
    onDelete: 'CASCADE',
    nullable: true,
  })
  @JoinColumn({ name: 'leadId' })
  lead?: Lead;

  @Column({ nullable: true })
  leadId?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;
}
