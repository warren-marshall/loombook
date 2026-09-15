import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsUrl,
  IsEnum,
  MaxLength,
} from 'class-validator';
import { ClientStatus } from '../entities/client.entity';

export class CreateClientDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  companyName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  industry?: string;

  @IsOptional()
  @IsUrl()
  website?: string;

  @IsOptional()
  @IsEnum(ClientStatus)
  status?: ClientStatus;
}
