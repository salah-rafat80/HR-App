import { Test, TestingModule } from '@nestjs/testing';
import { LeaveController } from './leave.controller';
import { LeaveService } from './leave.service';

describe('LeaveController', () => {
  let controller: LeaveController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [LeaveController],
      providers: [
        {
          provide: LeaveService,
          useValue: {
            getBalances: jest.fn(),
            getMyRequests: jest.fn(),
            applyLeave: jest.fn(),
            approveStep: jest.fn(),
            rejectStep: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<LeaveController>(LeaveController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
