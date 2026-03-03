import React, { useState } from 'react';
import { Character, Locale } from '../types/Character';
import { fetchNui } from '../utils/fetchNui';

interface Props {
  initialCharacters: Character[];
  canDelete: boolean;
  maxSlots: number;
  locale: Locale;
}

const CharacterSelection: React.FC<Props> = ({ initialCharacters, canDelete, maxSlots, locale }) => {
  const [characters, setCharacters] = useState<Character[]>(initialCharacters);
  const [selected, setSelected] = useState<Character | null>(
    initialCharacters.find(c => c.isActive) || initialCharacters[0] || null
  );
  const [confirmDelete, setConfirmDelete] = useState(false);

  const activeChar = selected;

  const handleSelectSlot = (slotId: string, isNew: boolean) => {
    if (isNew) {
      fetchNui('CreateCharacter');
      return;
    }
    if (selected?.id === slotId) return;
    const updated = characters.map(c => ({ ...c, isActive: c.id === slotId }));
    setCharacters(updated);
    setSelected(updated.find(c => c.id === slotId) || null);
    setConfirmDelete(false);
    fetchNui('SelectCharacter', { id: slotId });
  };

  const handlePlay = () => {
    fetchNui('PlayCharacter');
  };

  const handleQuit = () => {
    fetchNui('QuitGame');
  };

  const handleDelete = () => {
    if (!confirmDelete) {
      setConfirmDelete(true);
      return;
    }
    if (!selected) return;
    fetchNui('DeleteCharacter');
    const remaining = characters.filter(c => c.id !== selected.id);
    if (remaining.length > 0) {
      const updated = remaining.map((c, i) => ({ ...c, isActive: i === 0 }));
      setCharacters(updated);
      setSelected(updated[0]);
    } else {
      setCharacters([]);
      setSelected(null);
      fetchNui('CreateCharacter');
    }
    setConfirmDelete(false);
  };

  const filledSlots = characters.map(c => parseInt(c.id));
  const slots: { id: number; filled: boolean }[] = [];
  for (let i = 1; i <= maxSlots; i++) {
    if (filledSlots.includes(i)) {
      slots.push({ id: i, filled: true });
    }
  }
  if (characters.length < maxSlots) {
    slots.push({ id: 0, filled: false });
  }

  return (
    <div className="mc-screen">
      {/* Character info - top right */}
      {activeChar && (
        <div className="mc-character-info">
          <span className="mc-firstname">{activeChar.firstname}</span>
          <span className="mc-lastname">{activeChar.lastname.toUpperCase()}</span>
          <div className="mc-separator" />
          <span className="mc-job">{activeChar.occupation}</span>
        </div>
      )}

      {/* Actions - left */}
      <div className="mc-actions">
        {activeChar && !confirmDelete && (
          <button className="mc-action-btn mc-play" onClick={handlePlay} disabled={activeChar.disabled}>
            {locale.play_game}
          </button>
        )}
        {canDelete && activeChar && !confirmDelete && (
          <button className="mc-action-btn mc-delete" onClick={handleDelete}>
            {locale.delete}
          </button>
        )}
        {!confirmDelete && (
          <button className="mc-action-btn mc-quit" onClick={handleQuit}>
            {locale.quit}
          </button>
        )}

        {confirmDelete && (
          <div className="mc-confirm">
            <p className="mc-confirm-text">{locale.delete_confirm}</p>
            <div className="mc-confirm-buttons">
              <button className="mc-action-btn mc-confirm-yes" onClick={handleDelete}>
                {locale.yes}
              </button>
              <button className="mc-action-btn mc-confirm-no" onClick={() => setConfirmDelete(false)}>
                {locale.no}
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Slot selector - bottom right */}
      <div className="mc-slots">
        {slots.map(slot => {
          const char = characters.find(c => parseInt(c.id) === slot.id);
          const isActive = activeChar && parseInt(activeChar.id) === slot.id;
          return (
            <button
              key={slot.id}
              className={`mc-slot ${isActive ? 'active' : ''} ${!slot.filled ? 'empty' : ''}`}
              onClick={() => handleSelectSlot(slot.id.toString(), !slot.filled)}
            >
              {slot.filled ? slot.id : '+'}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default CharacterSelection;
