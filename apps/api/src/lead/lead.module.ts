import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LeadsService } from './lead.service';
import { LeadsController } from './lead.controller';
import { Lead } from './entities/lead.entity';
import { Client } from '../client/entities/client.entity';
import { Contact } from '../contact/entities/contact.entity';
import { EmailMessage } from '../email-messages/entities/email-message.entity';
import { Contract } from '../contract/entities/contract.entity';
import { Attachment } from '../attachment/entities/attachment.entity';
import { GmailModule } from '../gmail/gmail.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Lead,
      Client,
      Contact,
      EmailMessage,
      Contract,
      Attachment,
    ]),
    GmailModule,
  ],
  controllers: [LeadsController],
  providers: [LeadsService],
  exports: [LeadsService],
})
export class LeadModule {}
