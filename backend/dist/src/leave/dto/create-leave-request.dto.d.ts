export declare enum LeaveType {
    annual = "annual",
    sick = "sick",
    emergency = "emergency",
    maternityPaternity = "maternityPaternity",
    unpaid = "unpaid",
    study = "study",
    hajj = "hajj",
    bereavement = "bereavement"
}
export declare enum HalfDayPeriod {
    morning = "morning",
    afternoon = "afternoon"
}
export declare class CreateLeaveRequestDto {
    type: LeaveType;
    startDate: string;
    endDate: string;
    isHalfDay: boolean;
    halfDayPeriod?: HalfDayPeriod;
    reason: string;
    hasAttachment?: boolean;
}
