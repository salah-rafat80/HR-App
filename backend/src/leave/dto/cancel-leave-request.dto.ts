import { IsString, IsNotEmpty } from 'class-validator';

export class CancelLeaveRequestDto {
  @IsString()
  @IsNotEmpty()
  reason: string;
}
