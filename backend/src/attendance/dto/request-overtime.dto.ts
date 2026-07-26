import { IsNotEmpty, IsNumber, IsString } from 'class-validator';

export class RequestOvertimeDto {
  @IsNumber()
  @IsNotEmpty()
  hoursRequested: number;

  @IsString()
  @IsNotEmpty()
  reason: string;
}
