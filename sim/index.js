import { Dex, BattleStreams, RandomPlayerAI, Teams } from '@pkmn/sim';
import { TeamGenerators } from '@pkmn/randoms';
import readline from 'readline';


const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
});

Teams.setGeneratorFactory(TeamGenerators);
const bs = new BattleStreams.BattleStream()
const streams = BattleStreams.getPlayerStreams(bs);
const spec = { formatid: 'gen9randombattle' };

const p1spec = { name: 'Bot 1', team: Teams.generate('gen9randombattle') };
const p2spec = { name: 'Bot 2', team: Teams.generate('gen9randombattle') };

//const p1 = new RandomPlayerAI(streams.p1);
const p2 = new RandomPlayerAI(streams.p2);

//void p1.start();
void p2.start();

void (async () => {
    for await (const chunk of streams.p1) {
        pipeline(chunk);
    }
})();

void streams.omniscient.write(`>start ${JSON.stringify(spec)}
>player p1 ${JSON.stringify(p1spec)}
>player p2 ${JSON.stringify(p2spec)}`);

function cmd() {
    rl.question('', (res) => {
        streams.p1.write(res)
        cmd()
    })
}
cmd()
/**
 * 
 * @param {string} raw 
 */
function pipeline(raw) {
    if (raw.startsWith('|request|')) {
        const json = JSON.parse(raw.replace('|request|', ''))
        console.dir(json, { depth: null, colors: false })
        return
    }
    console.log(raw)
}