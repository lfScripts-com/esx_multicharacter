import CharacterSelection from './components/CharacterSelection';
import { useState, useEffect } from 'react';
import { useNuiEvent } from './utils/useNuiEvent'
import { Character, Locale } from './types/Character';
import { fetchNui } from './utils/fetchNui';

function App() {
  const [isVisible, setIsVisible] = useState<boolean>(false);
  const [characters, setCharacters] = useState<Character[]>([]);
  const [canDelete, setCanDelete] = useState<boolean>(false);
  const [maxSlots, setMaxSlots] = useState<number>(0);
  const [locale, setLocale] = useState<Locale>({ play_game: 'PLAY GAME', quit: 'QUIT', delete: 'DELETE', delete_confirm: '', yes: 'YES', no: 'NO' });

  useEffect(() => {
    fetchNui('nuiReady')
  }, [])

  useNuiEvent('ToggleMulticharacter', (data: any) => {
    if (data.show) {
      const validCharacters = data.Characters.filter((char: any) => char !== null);
      validCharacters.sort((a: any, b: any) => (a.id || 0) - (b.id || 0));

      const parsedCharacters: Character[] = validCharacters.map((char: any, index: number) => ({
        id: char.id.toString(),
        firstname: char.firstname || '',
        lastname: char.lastname || '',
        birthDate: char.dateofbirth,
        gender: char.sex?.toUpperCase() === 'MALE' ? 'MALE' : 'FEMALE',
        occupation: char.job || '',
        disabled: char.disabled,
        isActive: index === 0,
      }));

      setIsVisible(true);
      setCharacters(parsedCharacters);
      setCanDelete(data.CanDelete);
      setMaxSlots(data.AllowedSlot);
      if (data.Locale) setLocale(data.Locale);
    } else {
      setIsVisible(false);
      setCharacters([]);
    }
  })

  return isVisible ? (
    <CharacterSelection
      initialCharacters={characters}
      canDelete={canDelete}
      maxSlots={maxSlots}
      locale={locale}
    />
  ) : null;
}

export default App;
