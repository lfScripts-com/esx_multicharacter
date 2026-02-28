export interface Character {
  id: string;
  firstname: string;
  lastname: string;
  birthDate: string;
  gender: 'MALE' | 'FEMALE';
  occupation: string;
  isActive?: boolean;
  disabled?: boolean;
}

export interface Locale {
  play_game: string;
  quit: string;
  delete: string;
  delete_confirm: string;
  yes: string;
  no: string;
}
