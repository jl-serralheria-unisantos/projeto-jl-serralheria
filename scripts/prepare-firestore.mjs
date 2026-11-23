// Prepara o candidato antes da validação. A publicação é uma operação separada.
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import assert from 'node:assert/strict';

const [config, output] = process.argv.slice(2);
assert(config && output, 'Uso: node scripts/prepare-firestore.mjs <defines.json> <candidato.rules>');
const template = new URL('../firestore.rules', import.meta.url);
const { OWNER_UID: uid } = JSON.parse(await readFile(config, 'utf8'));
assert(typeof uid === 'string' && uid.trim() && uid.length <= 128, 'Preencha OWNER_UID na configuração do build.');
const source = await readFile(template, 'utf8');
const marker = "return '';";
assert.equal(source.split(marker).length, 2, 'Template inesperado');
await mkdir(dirname(resolve(output)), {recursive: true});
// wx também protege o template e candidatos anteriores contra sobrescrita acidental.
const candidate = source.replace(marker, () => 'return ' + JSON.stringify(uid) + ';');
try {
  await writeFile(output, candidate, {flag: 'wx'});
} catch (error) {
  if (error.code !== 'EEXIST') throw error;
  assert.equal(await readFile(output, 'utf8') === candidate, true,
    'Já existe outro conteúdo no destino. Escolha um caminho para o novo candidato.');
}
console.log('Candidato preparado em', output);
