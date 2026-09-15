// update-lead.dto.ts
import {
  IsEnum,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { LeadStatus } from '../entities/lead.entity';

export class UpdateLeadDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  businessName?: string;

  @IsOptional()
  @IsUrl()
  @Transform(({ value }: { value: string }) =>
    value === '' ? undefined : value,
  )
  website?: string;

  @IsOptional()
  @IsEnum(LeadStatus)
  status?: LeadStatus;
}
