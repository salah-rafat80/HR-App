import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsOptional,
  IsEmpty,
} from 'class-validator';
import { Transform } from 'class-transformer';

export class CreateAnnouncementDto {
  @IsString()
  @Transform(({ value }: { value: string }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsNotEmpty()
  @MaxLength(100)
  title: string;

  @IsString()
  @Transform(({ value }: { value: string }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsNotEmpty()
  @MaxLength(2000)
  content: string;

  @IsOptional()
  @IsEmpty({
    message: 'Global release only: department scoping is not yet supported',
  })
  department?: string;
}
