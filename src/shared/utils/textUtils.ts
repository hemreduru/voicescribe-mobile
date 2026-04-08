export const removeOverlap = (prevText: string, currentText: string): string => {
  if (!prevText || !currentText) return currentText;

  const prevWords = prevText.split(' ').filter((w) => w.length > 0);
  const currWords = currentText.split(' ').filter((w) => w.length > 0);

  if (prevWords.length === 0 || currWords.length === 0) return currentText;

  // Since we overlap about 2 seconds, the overlap shouldn't be more than ~10-15 words.
  // We'll check from max overlap down to 1 word.
  const maxOverlapWords = Math.min(prevWords.length, currWords.length, 15);

  let bestOverlapLength = 0;
  
  // Try to find the longest matching suffix of prevWords that is a prefix of currWords
  for (let i = 1; i <= maxOverlapWords; i++) {
    const prevSuffix = prevWords.slice(-i).join(' ').toLowerCase();
    const currPrefix = currWords.slice(0, i).join(' ').toLowerCase();

    // To be robust against minor whisper transcription variations, we can allow a small Levenshtein distance
    // But exact match for now is safest and very fast for clean audio
    if (prevSuffix === currPrefix) {
      bestOverlapLength = i;
    }
  }

  // If we found an exact word overlap
  if (bestOverlapLength > 0) {
    return currWords.slice(bestOverlapLength).join(' ');
  }

  // If no exact match, try a fuzzy match (Levenshtein) on the suffix and prefix strings
  // Just a simple heuristic: if a 5+ word suffix is >80% similar to prefix, cut it
  for (let i = Math.min(10, maxOverlapWords); i >= 3; i--) {
      const prevSuffix = prevWords.slice(-i).join(' ').toLowerCase();
      const currPrefix = currWords.slice(0, i).join(' ').toLowerCase();
      
      if (levenshteinDistance(prevSuffix, currPrefix) <= i) { // roughly 1 char diff per word tolerated
          return currWords.slice(i).join(' ');
      }
  }

  return currentText;
};

// Standard Levenshtein distance
const levenshteinDistance = (a: string, b: string): number => {
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;

  const matrix = Array(b.length + 1).fill(null).map(() => Array(a.length + 1).fill(null));

  for (let i = 0; i <= a.length; i += 1) {
    matrix[0][i] = i;
  }

  for (let j = 0; j <= b.length; j += 1) {
    matrix[j][0] = j;
  }

  for (let j = 1; j <= b.length; j += 1) {
    for (let i = 1; i <= a.length; i += 1) {
      const indicator = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[j][i] = Math.min(
        matrix[j][i - 1] + 1, // insertion
        matrix[j - 1][i] + 1, // deletion
        matrix[j - 1][i - 1] + indicator // substitution
      );
    }
  }

  return matrix[b.length][a.length];
};
