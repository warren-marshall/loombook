import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientService } from './client.service';
import { ClientController } from './client.controller';
import { Client } from './entities/client.entity';
import { User } from '../user/entities/user.entity';
import { Invoice } from '../invoice/entities/invoice.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Client, User, Invoice])],
  controllers: [ClientController],
  providers: [ClientService],
})
export class ClientModule {}
