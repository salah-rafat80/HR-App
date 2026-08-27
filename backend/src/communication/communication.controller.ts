import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { CommunicationService } from './communication.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../auth/roles.enum';

@Controller('communication')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CommunicationController {
  constructor(private readonly communicationService: CommunicationService) {}

  @Post('announcements')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  async create(
    @Body() createAnnouncementDto: CreateAnnouncementDto,
    @Request() req: { user: { userId: string } },
  ) {
    if (createAnnouncementDto.department) {
      throw new BadRequestException(
        'Department-specific announcements are not yet supported. Please leave department empty for a global announcement.',
      );
    }
    return this.communicationService.create(
      createAnnouncementDto,
      req.user.userId,
    );
  }

  @Get('announcements')
  findAll(@Request() req: { user: { userId: string } }) {
    return this.communicationService.findAll(req.user.userId);
  }
}
