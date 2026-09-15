import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ContactService } from './contact.service';
import { ContactController } from './contact.controller';
import { Contact } from './entities/contact.entity';
import { Client } from '../client/entities/client.entity';
import { Lead } from '../lead/entities/lead.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Contact, Client, Lead])],
  controllers: [ContactController],
  providers: [ContactService],
})
export class ContactModule {}
