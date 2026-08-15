import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { CompanySettingsService } from './company-settings.service';
import {
  CreateOfficeBranchDto,
  UpdateOfficeBranchDto,
} from './dto/office-branch.dto';
import { AssignUserBranchDto } from './dto/assign-user-branch.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../auth/roles.enum';

@Controller('company-settings')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CompanySettingsController {
  constructor(private readonly settingsService: CompanySettingsService) {}

  @Get('branches')
  async getBranches() {
    return this.settingsService.getBranches();
  }

  @Post('branches')
  @Roles(Role.superAdmin, Role.hrAdmin, Role.hr, Role.manager)
  async addBranch(@Body() data: CreateOfficeBranchDto) {
    return this.settingsService.addBranch(data);
  }

  @Patch('branches/:id')
  @Roles(Role.superAdmin, Role.hrAdmin, Role.hr, Role.manager)
  async updateBranch(
    @Param('id') id: string,
    @Body() data: UpdateOfficeBranchDto,
  ) {
    return this.settingsService.updateBranch(id, data);
  }

  @Get('users')
  @Roles(Role.superAdmin, Role.hrAdmin, Role.hr)
  getUsersForBranchAssignment() {
    return this.settingsService.getUsersForBranchAssignment();
  }

  @Patch('users/:userId/branch')
  @Roles(Role.superAdmin, Role.hrAdmin, Role.hr)
  async assignUserBranch(
    @Param('userId') userId: string,
    @Body() data: AssignUserBranchDto,
  ) {
    return this.settingsService.assignUserBranch(userId, data);
  }

  @Delete('branches/:id')
  @Roles(Role.superAdmin, Role.hrAdmin, Role.hr, Role.manager)
  async deleteBranch(@Param('id') id: string) {
    return this.settingsService.deleteBranch(id);
  }
}
