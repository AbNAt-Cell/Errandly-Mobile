export type ErrandDraft = {
  title?: string;
  description?: string;
  category?: string;
  urgency?: string;
  pickup_address?: string;
  pickup_latitude?: number;
  pickup_longitude?: number;
  destination_address?: string;
  destination_latitude?: number;
  destination_longitude?: number;
  budget?: number;
  item_details?: string;
  special_instructions?: string;
  clarifying_questions?: string[];
  confidence?: number;
};

export type ErrandFormFields = {
  title: string;
  category: string;
  description: string;
  urgency: 'standard' | 'urgent' | 'scheduled';
  pickup_address: string;
  pickup_latitude: number;
  pickup_longitude: number;
  destination_address: string;
  destination_latitude: number;
  destination_longitude: number;
  budget: number;
  item_details?: string;
  special_instructions?: string;
};

export function applyDraftToForm(
  draft: ErrandDraft,
  setValue: (name: keyof ErrandFormFields, value: ErrandFormFields[keyof ErrandFormFields]) => void,
) {
  if (draft.title) setValue('title', draft.title);
  if (draft.description) setValue('description', draft.description);
  if (draft.category) setValue('category', draft.category);
  if (draft.urgency && ['standard', 'urgent', 'scheduled'].includes(draft.urgency)) {
    setValue('urgency', draft.urgency as ErrandFormFields['urgency']);
  }
  if (draft.pickup_address) setValue('pickup_address', draft.pickup_address);
  if (draft.pickup_latitude != null) setValue('pickup_latitude', Number(draft.pickup_latitude));
  if (draft.pickup_longitude != null) setValue('pickup_longitude', Number(draft.pickup_longitude));
  if (draft.destination_address) setValue('destination_address', draft.destination_address);
  if (draft.destination_latitude != null) setValue('destination_latitude', Number(draft.destination_latitude));
  if (draft.destination_longitude != null) setValue('destination_longitude', Number(draft.destination_longitude));
  if (draft.budget != null && draft.budget >= 500) setValue('budget', Number(draft.budget));
  if (draft.item_details) setValue('item_details', draft.item_details);
  if (draft.special_instructions) setValue('special_instructions', draft.special_instructions);
}
