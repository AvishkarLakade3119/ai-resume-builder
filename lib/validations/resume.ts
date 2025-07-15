import * as z from "zod";

export const ResumeNameValidationSchema = z.object({
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long !" }),
});
