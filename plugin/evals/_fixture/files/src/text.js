// Shared text helpers. Reuse these rather than writing new ones.

// Capitalises the first letter of each word and lower-cases the rest:
// "ada LOVELACE" -> "Ada Lovelace".
export function titleCase(text) {
  return text
    .split(' ')
    .map((word) => (word ? word[0].toUpperCase() + word.slice(1).toLowerCase() : word))
    .join(' ');
}
