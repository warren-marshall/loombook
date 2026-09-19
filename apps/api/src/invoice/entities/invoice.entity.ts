import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Client } from '../../client/entities/client.entity';

@Entity('invoices')
export class Invoice {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'int' })
  amountCents!: number;

  @Column({ type: 'varchar', default: 'draft' })
  status!: string;

  @ManyToOne(() => Client, (client) => client.invoices, {
    onDelete: 'CASCADE',
    nullable: false,
  })
  @JoinColumn({ name: 'clientId' })
  client!: Client;

  @Column({ type: 'uuid' })
  clientId!: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;
}
