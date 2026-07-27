import { Controller, Get, Post, Patch, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { CompanySettingsService } from './company-settings.service';
import { CreateOfficeBranchDto, UpdateOfficeBranchDto } from './dto/office-branch.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('company-settings')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CompanySettingsController {
  constructor(private readonly settingsService: CompanySettingsService) {}

  @Get('branches')
  async getBranches() {
    return this.settingsService.getBranches();
  }

  @Post('branches')
  @Roles('superAdmin', 'hr', 'hrAdmin', 'admin', 'manager')
  async addBranch(@Body() data: CreateOfficeBranchDto) {
    return this.settingsService.addBranch(data);
  }

  @Patch('branches/:id')
  @Roles('superAdmin', 'hr', 'hrAdmin', 'admin', 'manager')
  async updateBranch(@Param('id') id: string, @Body() data: UpdateOfficeBranchDto) {
    return this.settingsService.updateBranch(id, data);
  }

  @Delete('branches/:id')
  @Roles('superAdmin', 'hr', 'hrAdmin', 'admin', 'manager')
  async deleteBranch(@Param('id') id: string) {
    return this.settingsService.deleteBranch(id);
  }
}

