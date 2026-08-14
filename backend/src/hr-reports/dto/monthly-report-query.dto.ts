import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class MonthlyReportQueryDto {
  @IsString()
  @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, {
    message: 'month must use YYYY-MM format',
  })
  month: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  department?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  employeeId?: string;
}
