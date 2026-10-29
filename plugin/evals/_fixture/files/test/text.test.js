import { test } from 'node:test';
import assert from 'node:assert/strict';
import { titleCase } from '../src/text.js';

test('title-cases each word', () => {
  assert.equal(titleCase('ada LOVELACE'), 'Ada Lovelace');
});
