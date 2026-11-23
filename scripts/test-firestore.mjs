// Teste isolado. Endereços fixos de loopback e projeto demo impedem acesso à produção.
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';

const project = 'demo-jl-serralheria';
const auth = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:';
const firestore = 'http://127.0.0.1:8080';
const documents = firestore + '/v1/projects/' + project + '/databases/(default)/documents/';
const rulesUrl = firestore + '/emulator/v1/projects/' + project + ':securityRules';
const template = await readFile(new URL('../firestore.rules', import.meta.url), 'utf8');

async function authRequest(action, payload, expected = 200, admin = false) {
  const res = await fetch(auth + action + '?key=demo', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(admin ? { Authorization: 'Bearer owner' } : {}) },
    body: JSON.stringify(payload),
  });
  assert.equal(res.status, expected, action);
  return res.json();
}

async function installRules(content) {
  const res = await fetch(rulesUrl, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({ rules: { files: [{ name: 'firestore.rules', content }] } }),
  });
  assert.equal(res.status, 200, await res.text());
}

async function operation(method, path, token, expected, value = 1) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = 'Bearer ' + token;
  const body = method === 'PATCH' ? JSON.stringify({ fields: { valor: { integerValue: String(value) } } }) : undefined;
  const res = await fetch(documents + path, { method, headers, body });
  assert.equal(res.status, expected, method + ' ' + path + ' ' + (res.ok ? '' : await res.text()));
  if (method === 'GET' && expected === 200 && path.includes('/')) {
    assert.equal((await res.json()).fields.valor.integerValue, String(value));
  }
}

function candidateUid(content, buildUid) {
  assert(typeof buildUid === 'string' && buildUid.trim(), 'OWNER_UID ausente no build');
  const match = content.match(/function\s+ownerUid\(\)\s*\{\s*(?:\/\/[^\n]*\n\s*)*return\s+("(?:\\.|[^"\\])*")\s*;\s*\}/);
  assert(match, 'Candidato sem UID configurado');
  const uid = JSON.parse(match[1]);
  assert.equal(uid, buildUid, 'UID do candidato difere do build');
  return uid;
}

const [candidatePath, configPath] = process.argv.slice(2);
assert(candidatePath && configPath, 'Informe o candidato e o JSON usado no build.');
const bytes = await readFile(candidatePath);
const candidate = new TextDecoder('utf-8', {fatal: true, ignoreBOM: true}).decode(bytes);
const config = JSON.parse(await readFile(configPath, 'utf8'));
const uid = candidateUid(candidate, config.OWNER_UID);
assert.throws(() => candidateUid(template, uid), /sem UID/);
assert.throws(() => candidateUid(candidate, ''), /ausente/);
assert.throws(() => candidateUid(candidate, uid + '-outro'), /difere/);
assert.match(template, /return '';/);

const id = randomUUID();
const email = id + '@example.test';
const password = randomUUID();
const credentials = {email, password, returnSecureToken: true};
await authRequest('signUp', {...credentials, localId: uid}, 200, true);
const other = await authRequest('signUp', {...credentials, email: 'other-' + email});
await authRequest('signInWithPassword', {...credentials, password: randomUUID()}, 400);
const login = await authRequest('signInWithPassword', credentials);
assert.equal(login.localId, uid);

// O mesmo usuário entra por telefone no Auth Emulator para isolar a condição de provedor.
const phoneNumber = '+16505550123';
await authRequest('update', {localId: uid, phoneNumber}, 200, true);
const {sessionInfo} = await authRequest('sendVerificationCode', {phoneNumber});
const codesResponse = await fetch('http://127.0.0.1:9099/emulator/v1/projects/' + project + '/verificationCodes');
assert.equal(codesResponse.status, 200);
const {verificationCodes} = await codesResponse.json();
const code = verificationCodes.find(entry => entry.sessionInfo === sessionInfo).code;
const phone = await authRequest('signInWithPhoneNumber', {sessionInfo, code});
assert.equal(phone.localId, uid);

async function denied(path, token) {
  await operation('GET', path, token, 403);
  await operation('PATCH', path + '-novo', token, 403);
  await operation('PATCH', path, token, 403);
  await operation('DELETE', path, token, 403);
}

const collections = ['clientes', 'produtos', 'servicos', 'orcamentos'];
await installRules(template);
for (const collection of collections) {
  for (const token of [login.idToken, other.idToken, null, phone.idToken]) {
    await operation('GET', collection, token, 403);
    await denied(collection + '/' + id, token);
  }
}
try {
  await installRules(candidate);
  for (const collection of collections) {
    const path = collection + '/' + id;
    await operation('PATCH', path, login.idToken, 200);
    await operation('GET', collection, login.idToken, 200);
    await operation('PATCH', path, login.idToken, 200, 2);
    await operation('GET', path, login.idToken, 200, 2);
    for (const token of [other.idToken, null, phone.idToken]) {
      await operation('GET', collection, token, 403);
      await denied(path, token);
    }
    await operation('DELETE', path, login.idToken, 200);
  }
  for (const path of ['outras/' + id, 'clientes/' + id + '/privado/item']) {
    await denied(path, login.idToken);
    await operation('GET', path.slice(0, path.lastIndexOf('/')), login.idToken, 403);
  }
} finally {
  await installRules(template);
}
const hash = createHash('sha256').update(bytes).digest('hex');
await writeFile(candidatePath + '.sha256', hash + '\n');
console.log('OK: template fechado, candidato verificado, CRUD e negações nas quatro coleções. SHA-256:', hash);
