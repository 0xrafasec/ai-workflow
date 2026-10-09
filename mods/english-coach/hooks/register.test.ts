import { expect, test } from 'claude-code/testing'
import { asText, ownWords, parseFeedback, shouldCheck } from './register'

test('skips slash commands, shell escapes and very short input', () => {
  expect(shouldCheck('/clear')).toBe(false)
  expect(shouldCheck('! ls -la /tmp now')).toBe(false)
  expect(shouldCheck('yes do it')).toBe(false)
  expect(shouldCheck('pull our new updates from ai-workflow')).toBe(true)
})

test('strips pasted content and code fences', () => {
  const t = 'look at this <pasted_content id="x">some log</pasted_content> and ```code``` please'
  expect(ownWords(t)).toBe('look at this   and   please')
})

test('parses a reply, dropping malformed issues', () => {
  const reply = 'Sure: {"issues":[{"kind":"grammar","original":"a feedback","improved":"feedback","why":"uncountable"},{"kind":"style","original":"x","improved":"y"},{"kind":"fluency","original":"same","improved":"same"}],"natural":"Give me feedback."}'
  expect(parseFeedback(reply)).toEqual({
    issues: [{ kind: 'grammar', original: 'a feedback', improved: 'feedback', why: 'uncountable' }],
    natural: 'Give me feedback.',
  })
})

test('treats an empty or broken reply correctly', () => {
  expect(parseFeedback('{"issues":[],"natural":"ignored"}')).toEqual({ issues: [], natural: null })
  expect(parseFeedback('looks fine')).toBeNull()
  expect(parseFeedback('{not json}')).toBeNull()
})

test('formats a bulleted transcript line', () => {
  const text = asText({
    issues: [{ kind: 'fluency', original: 'not usual', improved: 'unusual', why: 'more idiomatic' }],
    natural: null,
  })
  expect(text).toBe('✎ English\n  • [fluency] "not usual" → "unusual" — more idiomatic')
})
