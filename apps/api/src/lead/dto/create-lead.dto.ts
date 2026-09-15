import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';
import { Transform } from 'class-transformer';

export class CreateLeadDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  subject!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(5000)
  message!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  businessName!: string;

  @IsOptional()
  @IsUrl()
  @Transform(({ value }: { value: string }) =>
    value === '' ? undefined : value,
  )
  website?: string;
}
