"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateLeaveRequestDto = exports.HalfDayPeriod = exports.LeaveType = void 0;
const class_validator_1 = require("class-validator");
var LeaveType;
(function (LeaveType) {
    LeaveType["annual"] = "annual";
    LeaveType["sick"] = "sick";
    LeaveType["emergency"] = "emergency";
    LeaveType["maternityPaternity"] = "maternityPaternity";
    LeaveType["unpaid"] = "unpaid";
    LeaveType["study"] = "study";
    LeaveType["hajj"] = "hajj";
    LeaveType["bereavement"] = "bereavement";
})(LeaveType || (exports.LeaveType = LeaveType = {}));
var HalfDayPeriod;
(function (HalfDayPeriod) {
    HalfDayPeriod["morning"] = "morning";
    HalfDayPeriod["afternoon"] = "afternoon";
})(HalfDayPeriod || (exports.HalfDayPeriod = HalfDayPeriod = {}));
class CreateLeaveRequestDto {
    type;
    startDate;
    endDate;
    isHalfDay;
    halfDayPeriod;
    reason;
    hasAttachment;
}
exports.CreateLeaveRequestDto = CreateLeaveRequestDto;
__decorate([
    (0, class_validator_1.IsEnum)(LeaveType),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateLeaveRequestDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateLeaveRequestDto.prototype, "startDate", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateLeaveRequestDto.prototype, "endDate", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", Boolean)
], CreateLeaveRequestDto.prototype, "isHalfDay", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(HalfDayPeriod),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateLeaveRequestDto.prototype, "halfDayPeriod", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateLeaveRequestDto.prototype, "reason", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Boolean)
], CreateLeaveRequestDto.prototype, "hasAttachment", void 0);
//# sourceMappingURL=create-leave-request.dto.js.map