import { Injectable, Logger } from '@nestjs/common';

export interface LeadNotification {
  name: string;
  email: string;
  subject?: string;
  businessName?: string;
  website?: string;
  message: string;
}

// Placeholder until the real Gmail integration is built: logs the
// notification instead of sending it.
@Injectable()
export class GmailService {
  private readonly logger = new Logger(GmailService.name);

  sendLeadNotification(lead: LeadNotification): Promise<void> {
    this.logger.log(`New lead from ${lead.name} <${lead.email}>`);
    return Promise.resolve();
  }
}
