const pptxgen = require('pptxgenjs');
const p = new pptxgen();
p.layout='LAYOUT_WIDE'; p.author='Parth Sevak'; p.title='Curb Cut';

/* Palette measured before use. On the F5F3ED ground: ink 16.2:1, soft 8.5:1,
   green 7.7:1, red 7.5:1, gold 4.4:1 so gold is large-text and fills only. */
const GROUND='F5F3ED', SURF='FFFFFF', SUNK='E7E3D8', LINE='D3CEC0',
      INK='14171A', SOFT='42474C', MUTED='656B71',
      GOLD='9A6608', GOLDFILL='C9A227', GREEN='1F5546', RED='8A2F24',
      DEEP='20242A', PAPER='F7F5EF', DIMTX='A9B0B6', GOLDLT='E8C87A';
const H='Cambria', B='Calibri', M='Courier New';
const W=13.3, ML=0.85;

const light=()=>{const s=p.addSlide(); s.background={color:GROUND}; return s;};
const deep =()=>{const s=p.addSlide(); s.background={color:DEEP};   return s;};
const T=(s,o)=>s.addText(o.t,Object.assign({isTextBox:true,margin:0},o.o));

function chip(s,t,c){ T(s,{t,o:{x:ML,y:0.42,w:8,h:0.26,fontSize:9.5,fontFace:M,
  color:c||MUTED,charSpacing:1.7}}); }
function title(s,t,c){ T(s,{t,o:{x:ML,y:0.78,w:W-2*ML,h:1.0,fontSize:33,bold:true,
  fontFace:H,color:c||INK}}); }
function kicker(s,t){ T(s,{t,o:{x:ML,y:6.28,w:11.7,h:0.66,fontSize:16,fontFace:H,
  italic:true,color:GOLD}}); }
function src(s,t){ T(s,{t,o:{x:ML,y:7.02,w:11.7,h:0.3,fontSize:8.5,fontFace:M,color:MUTED}}); }
function divider(n,t,sub){ const s=deep();
  T(s,{t:n,o:{x:ML,y:2.5,w:2,h:1,fontSize:48,bold:true,fontFace:M,color:GOLDLT}});
  T(s,{t,o:{x:ML,y:3.45,w:11,h:0.9,fontSize:41,bold:true,fontFace:H,color:PAPER}});
  if(sub) T(s,{t:sub,o:{x:ML,y:4.5,w:10,h:0.5,fontSize:16,fontFace:B,color:DIMTX}});
  return s; }
function voice(q,attrib,note,size,still){ const s=deep();
  T(s,{t:'“',o:{x:ML-0.18,y:0.72,w:1.5,h:1.45,fontSize:88,fontFace:H,color:GOLDLT}});
  T(s,{t:q,o:{x:ML,y:2.24,w:11.4,h:2.8,fontSize:size||33,fontFace:H,italic:true,
    color:PAPER,lineSpacingMultiple:1.2}});
  T(s,{t:attrib,o:{x:ML,y:5.35,w:11.4,h:0.7,fontSize:12,fontFace:M,color:DIMTX}});
  if(still) T(s,{t:still,o:{x:ML,y:6.15,w:11.4,h:0.7,fontSize:13.5,fontFace:H,
    italic:true,color:GOLDLT}});
  if(note) s.addNotes(note); return s; }

/* box + label helper for the architecture drawings, native shapes so every
   rectangle stays editable in PowerPoint */
function box(s,x,y,w,h,label,sub,opts){
  const o=opts||{};
  s.addShape(p.ShapeType.roundRect,{x,y,w,h,rectRadius:0.04,
    fill:{color:o.fill||SURF}, line:{color:o.line||LINE,width:o.lw||1.25}});
  T(s,{t:label,o:{x:x+0.14,y:y+0.11,w:w-0.28,h:0.32,fontSize:o.fs||11.5,bold:true,
    fontFace:B,color:o.tc||INK}});
  if(sub) T(s,{t:sub,o:{x:x+0.14,y:y+0.42,w:w-0.28,h:h-0.5,fontSize:9.5,fontFace:M,
    color:o.sc||MUTED}});
}
function arrow(s,x,y,w,h,c){
  s.addShape(p.ShapeType.line,{x,y,w,h,
    line:{color:c||SOFT,width:1.4,endArrowType:'triangle'}});
}

/* ---------------------------------------------------------------- 1 TITLE */
{ const s=deep();
  T(s,{t:'CURB CUT',o:{x:ML,y:2.2,w:9,h:1.25,fontSize:60,bold:true,fontFace:H,
    color:PAPER,charSpacing:1}});
  T(s,{t:'Accommodation without disclosure.',o:{x:ML,y:3.4,w:9.5,h:0.6,fontSize:21,
    fontFace:H,italic:true,color:GOLDLT}});
  T(s,{t:'The process for asking is itself the barrier.',o:{x:ML,y:4.16,w:9.6,h:0.5,
    fontSize:15.5,fontFace:B,color:DIMTX}});
  T(s,{t:'Agentforce for Good   |   Dreamforce 2026   |   Builder Track   |   Abilityforce',
    o:{x:ML,y:6.6,w:11,h:0.35,fontSize:10.5,fontFace:M,color:DIMTX,charSpacing:1.2}});
  s.addNotes('Say the second line, then stop. Let the room have it.');
}

/* --------------------------------------------------------- 2 THE ROOM'S OWN */
{ const s=deep();
  T(s,{t:'You have already done this.',o:{x:ML,y:1.5,w:11.4,h:0.9,fontSize:42,
    bold:true,fontFace:H,color:PAPER}});
  T(s,{t:'Think of the last time something at work was quietly hard. The chair. The light. A meeting at the wrong hour for your body.',
    o:{x:ML,y:2.75,w:10.9,h:1.0,fontSize:21,fontFace:B,color:'D8DAD6'}});
  T(s,{t:'You worked out what it would take to ask. Who you would have to tell. How it would sound. And you decided it wasn\'t worth the conversation.',
    o:{x:ML,y:3.95,w:10.9,h:1.1,fontSize:21,fontFace:B,color:'D8DAD6'}});
  T(s,{t:'Now make it permanent, and make the conversation about your body.',
    o:{x:ML,y:5.35,w:10.9,h:0.8,fontSize:26,fontFace:H,italic:true,color:GOLDLT}});
  T(s,{t:'That\'s the whole problem. Everyone in this room has felt the small version of it.',
    o:{x:ML,y:6.45,w:11,h:0.5,fontSize:12.5,fontFace:M,color:DIMTX}});
  s.addNotes('Say the first line, then pause. Let people actually remember. Don\'t rush to the second line. Nobody needs a citation for this one because everybody has lived it.');
}

/* ------------------------------------------------------- 3 WHAT SHE ASKS FOR */
{ const s=light(); chip(s,'WHAT YOU DECIDED NOT TO DO');
  title(s,'Now imagine the form was mandatory.');
  T(s,{t:[{text:'You did that calculation privately and moved on.',options:{breakLine:true,bold:true}},
    {text:'For roughly three in ten people at work, that calculation isn\'t occasional. It\'s a standing condition of the job, and the price of getting it wrong isn\'t an awkward moment. It\'s being seen as difficult, or fragile, or not worth staffing.',options:{breakLine:true}},
    {text:'And the way through is almost never a conversation. It\'s this.',options:{bold:true}}],
    o:{x:ML,y:1.95,w:6.9,h:2.7,fontSize:16,fontFace:B,color:INK,paraSpaceAfter:12}});
  s.addShape(p.ShapeType.rect,{x:8.2,y:1.95,w:4.25,h:2.45,fill:{color:SURF},line:{color:RED,width:2}});
  T(s,{t:'Nature of disability',o:{x:8.5,y:2.25,w:3.6,h:0.35,fontSize:13,bold:true,fontFace:B,color:SOFT}});
  s.addShape(p.ShapeType.rect,{x:8.5,y:2.74,w:3.6,h:0.52,fill:{color:GROUND},line:{color:LINE,width:1}});
  s.addShape(p.ShapeType.rect,{x:8.62,y:2.84,w:0.02,h:0.3,fill:{color:INK},line:{color:INK,width:0}});
  T(s,{t:'Required',o:{x:8.5,y:3.38,w:3.6,h:0.3,fontSize:11,fontFace:B,color:RED}});
  T(s,{t:'Everything after this slide is about that box.',o:{x:8.5,y:3.75,w:3.7,h:0.5,
    fontSize:11.5,fontFace:H,italic:true,color:SOFT}});
  kicker(s,'It doesn\'t want to understand her. It wants a diagnosis, in writing, for somebody who will still be her manager on Monday.');
}

/* ------------------------------------------------------------- 4 THE STAKES */
{ const s=light(); chip(s,'WHY THIS IS NOT A SMALL THING');
  title(s,'One roadblock isn\'t one bad day.');
  const c=[['It ends careers quietly','Nobody is fired for needing an hour moved. They just stop being considered, stop being staffed, stop being asked.'],
           ['It compounds','A job lost is a reference lost, a gap on a CV, a mortgage refused. The roadblock is one afternoon. The consequence is a decade.'],
           ['It\'s almost always man-made','Not the condition itself, but the form, the login, the policy nobody can find, and the manager who needs proof.'],
           ['It reaches past the person','Their family. Their kids. The income that pays for the thing that would have helped.']];
  c.forEach(([t,d],i)=>{ const x=0.85+(i%2)*6.0, y=1.95+Math.floor(i/2)*1.75;
    s.addShape(p.ShapeType.roundRect,{x,y,w:5.6,h:1.5,rectRadius:0.05,
      fill:{color:SURF},line:{color:LINE,width:1.25}});
    T(s,{t,o:{x:x+0.22,y:y+0.16,w:5.2,h:0.35,fontSize:15,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x:x+0.22,y:y+0.58,w:5.2,h:0.85,fontSize:12,fontFace:B,color:SOFT}});
  });
  kicker(s,'We say everyone is equal. In a market, everyone is a transaction. It shouldn\'t take a dataset to argue that a person is worth an hour of flexibility. Here is the dataset anyway.');
  s.addNotes('This is the moral argument. Don\'t rush it and don\'t soften it.');
}

/* ---------------------------------------------------------------- 5 AGENDA */
{ const s=light(); chip(s,'AGENDA');
  title(s,'Five things, and an appendix.');
  const rows=[['01','The cost of telling','What disclosure takes out of a person, in their own words'],
              ['02','The evidence','WHO, Statistics Canada, US Bureau of Labor Statistics, and the study that measures the gap directly'],
              ['03','The build','Reference architecture, the channel layer, the grounding path, and the three rules the system won\'t break'],
              ['04','The honest part','What we shipped wrong, what two audits found, and what still fails'],
              ['05','The offer','Why good employers haven\'t done this, and what we will give the first ten who will'],
              ['A','Appendix','Every figure with its source, and the command that proves each one']];
  rows.forEach(([n,t,d],i)=>{ const y=1.88+i*0.72;
    T(s,{t:n,o:{x:ML,y,w:0.8,h:0.44,fontSize:19,bold:true,fontFace:M,color:GOLD}});
    T(s,{t,o:{x:1.8,y,w:3.3,h:0.44,fontSize:17,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x:5.3,y:y+0.03,w:7.2,h:0.58,fontSize:12,fontFace:B,color:SOFT}});
  });
  kicker(s,'Every figure is verifiable against a deployed org. The commands are on the last slide.');
}

/* ------------------------------------------------------------ 6 DIVIDER 01 */
divider('01','The cost of telling');

/* ------------------------------------------------------------- 7 VOICE TWO */
voice('...having to sit down and explain it six times a day to twenty different people adds to that exhaustion.',
 'Interview participant, workplace disclosure study, Proceedings of the ACM on\nHuman-Computer Interaction. One of eight people with invisible chronic conditions.',
 'This is the sentence the standing preference exists for. Call back to it later. If asked about the date: the gap it describes was measured again by Statistics Canada in 2022 and by the US Bureau of Labor Statistics in 2025, and it hasn\'t closed.',33,
 'Measured again in 2022 and 2025. It hasn\'t closed.');

/* --------------------------------------------------------- 8 THE REPEAT TAX */
{ const s=light(); chip(s,'01  THE COST OF TELLING');
  title(s,'Telling is never one conversation.');
  const items=[['Every new manager','starts the explanation again from nothing'],
               ['Every new team','has to be taught what the condition means'],
               ['Every meeting host','needs the same request, said the same way'],
               ['Every reorganisation','resets it, and there are two a year'],
               ['Every single time','she risks being believed a little less']];
  items.forEach(([t,d],i)=>{ const y=1.95+i*0.86;
    s.addShape(p.ShapeType.rect,{x:ML,y:y+0.12,w:0.06,h:0.42,fill:{color:GOLDFILL},line:{color:GOLDFILL,width:0}});
    T(s,{t,o:{x:1.15,y,w:3.5,h:0.42,fontSize:16,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x:4.9,y:y+0.03,w:7.6,h:0.5,fontSize:14,fontFace:B,color:SOFT}});
  });
  kicker(s,'Researchers call this the educational labour of disclosure. It falls entirely on the person who is already tired.');
  src(s,'Ganesh and Lazar, Proceedings of the ACM on Human-Computer Interaction, 2021. Eight interview participants with invisible chronic conditions.');
}

/* ------------------------------------------------------------ 9 DIVIDER 02 */
divider('02','The evidence','Four sources. They narrow rather than contradict.');

/* --------------------------------------------------------- 10 THE FOUR LENS */
{ const s=light(); chip(s,'02  THE EVIDENCE');
  title(s,'How many people, and by whose count.');
  const rows=[['1.3bn','16% of the world','significant disability','WHO, 2022'],
              ['27%','of Canadians 15+','one or more disabilities','Statistics Canada, 2022'],
              ['22.8%','employed, against 65.2%','all people with a disability','US BLS, 2025'],
              ['30%','of US white-collar','broad federal definition','Coqual']];
  rows.forEach(([n,l,def,st],i)=>{ const x=0.85+i*3.0;
    s.addShape(p.ShapeType.roundRect,{x,y:1.95,w:2.75,h:2.6,rectRadius:0.05,
      fill:{color:SURF},line:{color:LINE,width:1.25}});
    T(s,{t:n,o:{x:x+0.2,y:2.12,w:2.4,h:0.7,fontSize:30,bold:true,fontFace:H,color:GOLD}});
    T(s,{t:l,o:{x:x+0.2,y:2.86,w:2.4,h:0.45,fontSize:12.5,bold:true,fontFace:B,color:INK}});
    T(s,{t:def,o:{x:x+0.2,y:3.3,w:2.4,h:0.6,fontSize:11,fontFace:B,color:SOFT}});
    T(s,{t:st,o:{x:x+0.2,y:4.0,w:2.4,h:0.35,fontSize:9.5,fontFace:M,color:MUTED}});
  });
  T(s,{t:'They disagree because they count different things. WHO measures significant disability. The national definitions are broader.',
    o:{x:ML,y:4.75,w:11.7,h:0.5,fontSize:14,fontFace:B,color:INK}});
  kicker(s,'That gap is the argument, not a flaw in it. The wider the definition, the more people find they are counted, and the more of them have never told anyone at work.');
  src(s,'who.int  |  statcan.gc.ca Canadian Survey on Disability 2022  |  bls.gov Current Population Survey, about 60,000 households monthly  |  coqual.org');
}

/* ------------------------------------------------------- 11 THE UNMET NEED */
{ const s=light(); chip(s,'02  THE EVIDENCE');
  title(s,'The most common unmet need costs nothing.');
  T(s,{t:'Statistics Canada asked employed Canadians with disabilities what accommodation they needed, and whether they got it.',
    o:{x:ML,y:1.8,w:11.7,h:0.4,fontSize:14,fontFace:B,color:INK}});
  const needs=[['16.3%','Modified work hours',1],['11.6%','Modified or different duties',1],
               ['10.9%','Working from home',1],['10.7%','Modified or ergonomic workstation',0],
               ['10.3%','Special chair or back support',0]];
  needs.forEach(([pct,n,free],i)=>{ const y=2.35+i*0.62;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:parseFloat(pct)*0.34,h:0.4,
      fill:{color:free?GOLDFILL:SUNK},line:{color:free?GOLDFILL:LINE,width:0.75}});
    T(s,{t:pct,o:{x:ML+0.12,y:y+0.04,w:1,h:0.32,fontSize:12.5,bold:true,fontFace:M,color:INK}});
    T(s,{t:n,o:{x:6.5,y:y+0.03,w:4.0,h:0.35,fontSize:13.5,fontFace:B,color:INK}});
    T(s,{t:free?'costs nothing':'one-time cost',o:{x:10.6,y:y+0.05,w:1.9,h:0.3,
      fontSize:10.5,fontFace:M,color:free?GREEN:MUTED}});
  });
  T(s,{t:'35.4% of employed Canadians with disabilities have an UNMET accommodation need.',
    o:{x:ML,y:5.6,w:11.7,h:0.45,fontSize:17,bold:true,fontFace:H,color:INK}});
  kicker(s,'All five are in our library. The top three need somebody to say yes, and nothing else.');
  src(s,'Statistics Canada, Canadian Survey on Disability 2022. Job Accommodation Network: 61% of accommodations priced cost the employer nothing, n=1,425 of 5,406 respondents. 12% were reported ineffective, and we publish that too.');
}

/* ------------------------------------------------- 11b WHO THIS IS FOR */
{ const s=light(); chip(s,'02  THE EVIDENCE  |  WHO THIS IS FOR');
  title(s,'The user buys nothing. That\'s deliberate.');
  T(s,{t:'The moment somebody has to be inside a licence to get help, the people who need it most are the ones excluded. So the primary user needs no account, no employer relationship with us, and nobody to have bought anything.',
    o:{x:ML,y:1.8,w:11.7,h:0.75,fontSize:14,fontFace:B,color:INK}});
  const who=[['Contractors, temps, gig workers','no work login, no HR relationship, still expected to disclose'],
             ['People with invisible conditions','62% of disabled employees. Believed less, asked to prove more'],
             ['Deaf and hard-of-hearing workers','almost every escalation path ends at "give us a call"'],
             ['Anyone in their first weeks','least social capital, highest perceived cost of asking']];
  who.forEach(([n,d],i)=>{ const y=2.62+i*0.58;
    s.addShape(p.ShapeType.rect,{x:ML,y:y+0.1,w:0.06,h:0.4,fill:{color:GOLDFILL},line:{color:GOLDFILL,width:0}});
    T(s,{t:n,o:{x:1.15,y,w:4.3,h:0.4,fontSize:13.5,bold:true,fontFace:B,color:INK}});
    T(s,{t:d,o:{x:5.7,y:y+0.03,w:6.8,h:0.4,fontSize:12,fontFace:B,color:SOFT}});
  });
  T(s,{t:'WHO WOULD DEPLOY IT',o:{x:ML,y:5.05,w:5,h:0.3,fontSize:10,fontFace:M,color:MUTED,charSpacing:1.5,bold:true}});
  const dep=[['Employers with a programme','Disability:IN alone: 400+ corporations, 25 state affiliates'],
             ['Disability employment services','AbilityOne network: 36,000+ people placed in FY2024'],
             ['Independent living centres','no Salesforce budget, so MCP and the shared API exist for them']];
  dep.forEach(([n,d],i)=>{ const x=0.85+i*3.9;
    T(s,{t:n,o:{x,y:5.38,w:3.7,h:0.32,fontSize:12.5,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x,y:5.72,w:3.7,h:0.5,fontSize:10.5,fontFace:B,color:SOFT}});
  });
  kicker(s,'The gap isn\'t a spending gap. It\'s a process gap, which is cheaper to close and harder to sell, because no budget line says "the asking was too hard".');
}

/* ----------------------------------------------------------- 12 DIVIDER 03 */
divider('03','The build','An agent whose principal is the worker, not the employer.');

/* --------------------------------------------- 13 REFERENCE ARCHITECTURE */
{ const s=light(); chip(s,'03  THE BUILD  |  REFERENCE ARCHITECTURE');
  title(s,'Five layers. One of them is deliberately empty.');
  const L=[['PEOPLE','Anonymous web  ·  Voice  ·  Text  ·  Email  ·  Slack DM  ·  Any MCP assistant'],
           ['CONTROL','CurbCutKeyword. About 70 phrases resolved before any inference happens.'],
           ['DOOR','CurbCutChannelApi. One authenticated Apex REST endpoint every channel shares.'],
           ['LOGIC','Options ranker  ·  Redaction  ·  Consent gate  ·  Handoff  ·  Standing preference'],
           ['RECORD','9 objects, 61 fields, a delivery ledger, and no field for a diagnosis.']];
  L.forEach(([n,d],i)=>{ const y=1.94+i*0.85;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:1.5,h:0.68,
      fill:{color:i===4?SUNK:INK},line:{color:i===4?LINE:INK,width:1}});
    T(s,{t:n,o:{x:ML,y:y+0.22,w:1.5,h:0.3,fontSize:10,bold:true,fontFace:M,
      color:i===4?INK:PAPER,align:'center',charSpacing:1.2}});
    s.addShape(p.ShapeType.rect,{x:2.45,y,w:10.0,h:0.68,fill:{color:SURF},
      line:{color:LINE,width:1.25}});
    T(s,{t:d,o:{x:2.68,y:y+0.22,w:9.6,h:0.35,fontSize:12.5,fontFace:B,color:INK}});
    if(i<4) arrow(s,3.4,y+0.68,0,0.17);
  });
  kicker(s,'The model sits inside LOGIC and nowhere else. It may choose an action and phrase a reply. It may not invent an accommodation, a cost, or a precedent.');
}

/* ------------------------------------------------------ 13a TELEMETRY */
{ const s=light(); chip(s,'03  THE BUILD  |  TELEMETRY');
  title(s,'It can say it\'s failing somebody, without ever knowing what they said.');
  const cols=[['WHAT THE LEDGER HOLDS',GREEN,['When the attempt was made','Which channel, which direction','Whether it arrived, and why not','A salted hash of the handle','How much of today’s quota is spent']],
              ['WHAT IT CANNOT HOLD',RED,['The message','A raw phone number or address','A name','Anything about a body','A reason for turning a disclosure off']]];
  cols.forEach(([h,c,items],i)=>{ const x=ML+i*5.95;
    s.addShape(p.ShapeType.roundRect,{x,y:1.98,w:5.65,h:2.9,rectRadius:0.05,fill:{color:SURF},line:{color:c,width:1.5}});
    T(s,{t:h,o:{x:x+0.27,y:2.16,w:5.1,h:0.34,fontSize:11,bold:true,fontFace:M,color:c,charSpacing:1.2}});
    T(s,{t:items.map((t,j)=>({text:t,options:{bullet:true,breakLine:j<items.length-1}})),
      o:{x:x+0.27,y:2.6,w:5.1,h:2.2,fontSize:12.5,fontFace:B,color:INK,paraSpaceAfter:7}});
  });
  T(s,{t:'Six classes write to it. None can write a body, because there\'s no field for one. Five reports and one dashboard sit on top of it for the person on duty: who is waiting, what didn\'t arrive, who needs an interpreter.',
    o:{x:ML,y:5.08,w:11.6,h:0.9,fontSize:13.5,fontFace:B,color:SOFT}});
  kicker(s,'Telemetry that would let an employer read a conversation is surveillance with a dashboard. This one measures the system and protects the person.');
  src(s,'Message_Log__c   ·   9 fields, no body   ·   How_People_Reach_Us, Messages_That_Did_Not_Arrive, Who_Is_Waiting, Needs_An_Interpreter, Awaiting_A_Decision');
}

/* ------------------------------------------------ 13b THE GROUNDING PATH */
{ const s=light(); chip(s,'03  THE BUILD  |  GROUNDING');
  title(s,'Where the model is allowed to touch it.');
  const step=[['1','SENTENCE','"I get migraines from the office lighting." Stored as written, after a condition strip.'],
              ['2','TOKENS','Lowercased, whole words only. contains() once matched long inside alongside.'],
              ['3','RANK','Weighted by how much a word DISTINGUISHES, not whether it appears. A word in a quarter of rows scores nothing.'],
              ['4','SOQL','28 rows. Every one carries a source URL. No embeddings, no index, no vector store.'],
              ['5','PHRASE','The model may word the reply. It may not add a row, a cost, or a precedent.']];
  step.forEach(([n,k,d],i)=>{ const y=1.96+i*0.85;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:0.55,h:0.68,fill:{color:i===4?GOLDFILL:INK},
      line:{color:i===4?GOLDFILL:INK,width:1}});
    T(s,{t:n,o:{x:ML,y:y+0.2,w:0.55,h:0.32,fontSize:13,bold:true,fontFace:M,
      color:i===4?INK:PAPER,align:'center'}});
    T(s,{t:k,o:{x:1.55,y:y+0.21,w:1.5,h:0.32,fontSize:10.5,bold:true,fontFace:M,
      color:i===4?GOLD:MUTED,charSpacing:1.1}});
    s.addShape(p.ShapeType.rect,{x:3.15,y,w:9.3,h:0.68,fill:{color:SURF},line:{color:LINE,width:1.25}});
    T(s,{t:d,o:{x:3.38,y:y+0.2,w:8.9,h:0.4,fontSize:12,fontFace:B,color:INK}});
    if(i<4) arrow(s,1.12,y+0.68,0,0.17);
  });
  kicker(s,'Steps one to four contain no inference at all. The cheapest system is the one that doesn\'t ask a model a question it already knows the answer to.');
}

/* ------------------------------------------------------- 14 SWIM LANES */
{ const s=light(); chip(s,'03  THE BUILD  |  CHANNEL SWIM LANES');
  title(s,'The same contract, whichever door she comes through.');
  const cols=[['Control word','resolved in Apex'],['Grounded options','from 28 sourced rows'],
              ['Draft a request','in her own words'],['Send it','only on a clear yes'],
              ['Photo or signed video','to a human interpreter']];
  cols.forEach(([t,d],i)=>{ const x=3.15+i*1.98;
    T(s,{t,o:{x,y:1.85,w:1.9,h:0.3,fontSize:10.5,bold:true,fontFace:B,color:INK}});
    T(s,{t:d,o:{x,y:2.12,w:1.9,h:0.3,fontSize:8.5,fontFace:M,color:MUTED}});
  });
  const lanes=[['Web',   [1,1,1,1,1], 'anonymous, no login'],
               ['Voice', [0,1,0,0,0], 'live, no registration'],
               ['Text',  [1,1,1,1,0], 'live, via relay'],
               ['Email', [1,1,0,0,1], 'answers, never sends'],
               ['Slack', [1,1,0,0,0], 'DM only, never sends'],
               ['MCP',   [1,1,1,0,0], 'external assistants']];
  lanes.forEach(([n,marks,note],r)=>{ const y=2.55+r*0.62;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:11.6,h:0.54,
      fill:{color:r%2?SURF:GROUND},line:{color:LINE,width:0.75}});
    T(s,{t:n,o:{x:ML+0.15,y:y+0.13,w:1.1,h:0.3,fontSize:12.5,bold:true,fontFace:B,color:INK}});
    T(s,{t:note,o:{x:ML+1.25,y:y+0.16,w:1.6,h:0.28,fontSize:8.5,fontFace:M,color:MUTED}});
    marks.forEach((m,i)=>{ const x=3.15+i*1.98;
      if(m){ s.addShape(p.ShapeType.ellipse,{x:x+0.6,y:y+0.15,w:0.24,h:0.24,
        fill:{color:GREEN},line:{color:GREEN,width:0}}); }
      else { s.addShape(p.ShapeType.line,{x:x+0.58,y:y+0.27,w:0.28,h:0,
        line:{color:LINE,width:2}}); }
    });
  });
  kicker(s,'Email and Slack deliberately won\'t send. Agreeing in writing days later isn\'t the same as choosing in the moment.');
}

/* --------------------------------------------------------- 15 SAID ONCE */
{ const s=light(); chip(s,'03  THE BUILD  |  SAID ONCE');
  title(s,'Said once, instead of six times a day.');
  T(s,{t:'"...having to sit down and explain it six times a day to twenty different people."',
    o:{x:ML,y:1.8,w:11.7,h:0.45,fontSize:14.5,fontFace:H,italic:true,color:SOFT}});
  const steps=[['1','She writes it once','in her own words, never a category from a dropdown'],
               ['2','She chooses who sees it','her manager only, or meeting hosts, or her team'],
               ['3','She gets six characters','shown once, because we hold no account for her'],
               ['4','She can take it back','from any channel, immediately, no reason asked']];
  steps.forEach(([n,t,d],i)=>{ const x=0.85+i*3.0;
    s.addShape(p.ShapeType.ellipse,{x,y:2.5,w:0.56,h:0.56,fill:{color:GOLDFILL},line:{color:GOLDFILL,width:0}});
    T(s,{t:n,o:{x,y:2.61,w:0.56,h:0.36,fontSize:15,bold:true,fontFace:H,color:INK,align:'center'}});
    T(s,{t,o:{x,y:3.22,w:2.75,h:0.5,fontSize:15,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x,y:3.76,w:2.75,h:1.0,fontSize:12,fontFace:B,color:SOFT}});
    if(i<3) arrow(s,x+2.82,2.78,0.15,0);
  });
  T(s,{t:'A spent code and a wrong code return the same answer, so nobody can use this to test whether a stranger’s disclosure is still live.',
    o:{x:ML,y:5.0,w:11.7,h:0.5,fontSize:13.5,fontFace:B,color:INK}});
  kicker(s,'The alphabet leaves out O 0 I 1 S 5, the characters people confuse on a cracked screen or read aloud. An accessibility decision inside a cryptographic one.');
  s.addNotes('Verified live: set on the web, queried over SMS, revoked from Slack.');
}

/* --------------------------------------------------------- 16 THE ABSENCE */
{ const s=light(); chip(s,'03  THE BUILD  |  RESPONSIBLE AI');
  title(s,'There\'s no field for a diagnosis.');
  T(s,{t:'It isn\'t encrypted or locked behind a permission. It simply isn\'t there.',
    o:{x:ML,y:1.75,w:11.5,h:0.4,fontSize:16.5,fontFace:H,italic:true,color:GOLD}});
  s.addShape(p.ShapeType.roundRect,{x:ML,y:2.3,w:5.5,h:2.6,rectRadius:0.05,
    fill:{color:SURF},line:{color:GREEN,width:1.5}});
  T(s,{t:'PRESENT',o:{x:1.05,y:2.45,w:5,h:0.3,fontSize:10,fontFace:M,color:GREEN,charSpacing:1.5,bold:true}});
  const present=['Functional_Description__c','Inbound_Modality__c','Interpreter_Needed__c','Anonymous__c'];
  T(s,{t:present.map((t,i)=>({text:t,options:{breakLine:i<present.length-1}})),
    o:{x:1.05,y:2.82,w:5.1,h:1.9,fontSize:12,fontFace:M,color:INK,paraSpaceAfter:7}});
  s.addShape(p.ShapeType.roundRect,{x:6.95,y:2.3,w:5.5,h:2.6,rectRadius:0.05,
    fill:{color:SURF},line:{color:RED,width:1.5}});
  T(s,{t:'ABSENT, AND ENFORCED ABSENT',o:{x:7.15,y:2.45,w:5.1,h:0.3,fontSize:10,fontFace:M,color:RED,charSpacing:1.5,bold:true}});
  const absent=['Diagnosis__c','Condition__c','Disability_Type__c','Medical_Note__c','Severity__c','Prognosis__c'];
  T(s,{t:absent.map((t,i)=>({text:t,options:{strike:true,breakLine:i<absent.length-1}})),
    o:{x:7.15,y:2.82,w:5.1,h:2.0,fontSize:12,fontFace:M,color:RED,paraSpaceAfter:4}});
  T(s,{t:'0 matches across 61 fields in 9 objects. A build fails if anyone adds one.',
    o:{x:ML,y:5.1,w:11.5,h:0.4,fontSize:15,fontFace:B,bold:true,color:INK}});
  kicker(s,'Encryption defends against outsiders. Absence defends against the organisation holding the data, which is the actual adversary. A manager with legitimate access can still read an encrypted field.');
}

/* --------------------------------------------------------- 17 THE REFUSAL */
{ const s=deep(); chip(s,'03  THE BUILD  |  THE REFUSAL',DIMTX);
  T(s,{t:'Her manager asks the system what is wrong with her.',
    o:{x:ML,y:1.0,w:11.5,h:0.5,fontSize:15.5,fontFace:B,color:DIMTX}});
  T(s,{t:'"No. And not because of a permission setting."',
    o:{x:ML,y:1.7,w:11.5,h:0.9,fontSize:31,bold:true,fontFace:H,color:PAPER}});
  T(s,{t:'There\'s no field for a diagnosis, condition, disability type, medical note, severity or prognosis anywhere in this system. Nobody holds that, including the person who built it, and the person you are helping was never asked.',
    o:{x:ML,y:2.85,w:11.3,h:1.5,fontSize:15.5,fontFace:B,color:'D8DAD6'}});
  T(s,{t:'"A manager who asks you gets the same answer, and you can tell them it came from the system rather than from you."',
    o:{x:ML,y:4.6,w:11.3,h:1.0,fontSize:18.5,fontFace:H,italic:true,color:GOLDLT}});
  T(s,{t:'The refusal protects the person answering, too. That clause took longest to get right.',
    o:{x:ML,y:6.1,w:11,h:0.4,fontSize:12.5,fontFace:M,color:DIMTX}});
  s.addNotes('Four seconds of silence here. No music underneath it.');
}

/* ----------------------------------------------------------- 18 DIVIDER 04 */
divider('04','The honest part','What we shipped wrong, and what still fails.');

/* -------------------------------------------------- 19 THREE THINGS WRONG */
{ const s=light(); chip(s,'04  THE HONEST PART',RED);
  title(s,'Three things we shipped that were wrong.');
  const f=[['OFF did nothing.','Six control words were printed in our own copy and routed nowhere. The word that withdraws a disclosure returned "I don\'t have good information on that", and the sharing stayed on.'],
           ['The privacy policy was false.','It said a volunteered condition "isn\'t written to any record". It was stored word for word. Now stripped before the insert, with the claim rewritten to state its limit.'],
           ['Silence read as success.','Our adversarial scorer exited zero with every assertion inconclusive. It printed "silence must never read as success" and then did exactly that.']];
  f.forEach(([t,d],i)=>{ const y=1.95+i*1.42;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:0.06,h:1.15,fill:{color:RED},line:{color:RED,width:0}});
    T(s,{t,o:{x:1.15,y,w:3.4,h:0.5,fontSize:15,bold:true,fontFace:H,color:RED}});
    T(s,{t:d,o:{x:4.75,y,w:7.7,h:1.18,fontSize:12,fontFace:B,color:INK}});
  });
  kicker(s,'Each one now has a check that fails the build if it ever comes back.');
}

/* ------------------------------------------------- 19b THE REQUIRED TOOL */
{ const s=light(); chip(s,'04  THE HONEST PART');
  title(s,'The tool couldn\'t decide the thing that mattered.');

  s.addShape(p.ShapeType.roundRect,{x:ML,y:1.92,w:5.75,h:2.15,rectRadius:0.05,
    fill:{color:SURF},line:{color:GREEN,width:1.5}});
  T(s,{t:'What it passed',o:{x:1.13,y:2.12,w:5.2,h:0.36,fontSize:14.5,bold:true,
    fontFace:H,color:GREEN}});
  T(s,{t:'Sa11y, Salesforce\u2019s own axe-core matcher, reached through the lwc-experts toolset in the DX MCP server. Twelve component states, 131 checks, zero WCAG violations, against the 100-rule preset rather than the 64-rule default.',
    o:{x:1.13,y:2.58,w:5.2,h:1.3,fontSize:12,fontFace:B,color:INK}});

  s.addShape(p.ShapeType.roundRect,{x:7.0,y:1.92,w:5.45,h:2.15,rectRadius:0.05,
    fill:{color:SURF},line:{color:RED,width:1.5}});
  T(s,{t:'What it returned instead',o:{x:7.28,y:2.12,w:4.9,h:0.36,fontSize:14.5,
    bold:true,fontFace:H,color:RED}});
  T(s,{t:'On the signed video, WCAG 1.2.2 came back incomplete, not pass. Inside a test runner axe can\'t inspect media. So it couldn\'t settle it. A person using a screen reader would have settled it immediately.',
    o:{x:7.28,y:2.58,w:4.9,h:1.3,fontSize:12,fontFace:B,color:INK}});

  T(s,{t:'The obvious remedy was the forbidden one. That video is usually a Deaf person signing, and a machine caption would put words in somebody\u2019s mouth about their own body, then file them. So the video now says so itself, to the person who can\'t watch it:',
    o:{x:ML,y:4.32,w:11.6,h:0.88,fontSize:13.5,fontFace:B,color:SOFT}});
  s.addShape(p.ShapeType.rect,{x:ML,y:5.32,w:0.06,h:0.72,fill:{color:GOLDFILL},
    line:{color:GOLDFILL,width:0}});
  T(s,{t:'\u201cNo captions and no transcript, and none will be generated. This is waiting on a human interpreter.\u201d',
    o:{x:1.13,y:5.32,w:11.3,h:0.72,fontSize:16,fontFace:H,italic:true,color:INK}});

  kicker(s,'An incomplete isn\'t a pass. Reporting it as one would have been the easiest lie in the submission.');
}

/* ----------------------------------------------- 19c THE RAI SELF CHECK */
{ const s=light(); chip(s,'04  THE HONEST PART');
  title(s,'Our own repository couldn\'t rebuild us.');
  T(s,{t:'No Salesforce tool is published as an RAI Self Check, so we ran the same exercise against Salesforce\u2019s own five guidelines for responsible agentic AI, as something anybody can execute and disagree with.',
    o:{x:ML,y:1.88,w:11.6,h:0.72,fontSize:13.5,fontFace:B,color:SOFT}});

  const G=['ACCURACY','SAFETY','HONESTY','EMPOWERMENT','SUSTAINABILITY'];
  G.forEach((g,i)=>{ const x=ML+i*2.33;
    s.addShape(p.ShapeType.rect,{x,y:2.72,w:2.16,h:0.5,fill:{color:SUNK},line:{color:LINE,width:1}});
    T(s,{t:g,o:{x,y:2.86,w:2.16,h:0.28,fontSize:8.6,bold:true,fontFace:M,color:INK,align:'center',charSpacing:0.6}});
  });
  T(s,{t:'21 checks   |   19 passed   |   0 failed   |   2 undecided, and undecided is never counted as a pass',
    o:{x:ML,y:3.36,w:11.6,h:0.36,fontSize:12,fontFace:M,color:MUTED}});

  s.addShape(p.ShapeType.roundRect,{x:ML,y:3.86,w:11.6,h:1.62,rectRadius:0.05,
    fill:{color:SURF},line:{color:RED,width:1.5}});
  T(s,{t:'What it caught on the first run',o:{x:1.13,y:4.06,w:11.1,h:0.34,fontSize:14.5,bold:true,fontFace:H,color:RED}});
  T(s,{t:'The org held 28 library rows. The seed in our repository held 24. The four missing ones were the lighting rows added to fix the bias defect on the previous slide. Anyone deploying from our code would have rebuilt the agent with that defect back in, and every claim we make about fixing it would have been false on their org.',
    o:{x:1.13,y:4.5,w:11.1,h:0.9,fontSize:12.5,fontFace:B,color:INK}});

  T(s,{t:'It also produced a finding we withdrew. A check demanded every row state a cost; nine don\'t. But the code was already right: it says it has no figure and refuses to estimate one. We corrected the check, not the code, and left it in the file with a note that it was wrong the first time.',
    o:{x:ML,y:5.62,w:11.6,h:0.62,fontSize:12.5,fontFace:B,color:SOFT}});
  kicker(s,'A check that lies to you is worse than no check. So --selftest breaks four of them on purpose and asserts each one goes red.');
  src(s,'python3 tests/rai_self_check.py   ·   python3 tests/rai_self_check.py --selftest');
}

/* ---------------------------------------------------------- 20 ERROR RATE */
{ const s=light(); chip(s,'04  THE HONEST PART');
  title(s,'21 of 23. Three runs. Same score every time.');
  T(s,{t:[{text:'One assertion fails on every run',options:{bullet:true,breakLine:true,bold:true}},
    {text:'the agent doesn\'t reliably say out loud that it discarded a volunteered condition',options:{breakLine:true}},
    {text:'The second failure alternates',options:{bullet:true,breakLine:true,bold:true}},
    {text:'same build, same prompts, different answers, run to run',options:{}}],
    o:{x:ML,y:1.95,w:6.1,h:2.4,fontSize:14,fontFace:B,color:INK,paraSpaceAfter:8}});
  s.addShape(p.ShapeType.roundRect,{x:7.4,y:1.95,w:5.05,h:2.4,rectRadius:0.05,
    fill:{color:SURF},line:{color:GREEN,width:1.5}});
  T(s,{t:'Where it\'s deterministic, it\'s 100%',o:{x:7.68,y:2.18,w:4.5,h:0.5,
    fontSize:14.5,bold:true,fontFace:H,color:GREEN}});
  T(s,{t:'The four channels that compose their reply in Apex, web, text, email and Slack, say it every single time. Pinned by a test that exercises all four.',
    o:{x:7.68,y:2.72,w:4.5,h:1.4,fontSize:12.5,fontFace:B,color:INK}});
  T(s,{t:'"Good" is 23 of 23 with zero variance across five runs. Getting there means moving anything safety critical out of the model’s narration and into code that runs whether or not it remembers.',
    o:{x:ML,y:4.6,w:11.5,h:0.9,fontSize:14.5,fontFace:H,italic:true,color:INK}});
  T(s,{t:'137 Apex   |   508 invariants   |   333 accessibility   |   131 Sa11y   |   28 contrast   |   16 reading level   |   all passing, every build',
    o:{x:ML,y:5.7,w:11.7,h:0.5,fontSize:12,fontFace:M,color:SOFT}});
}

/* --------------------------------------------------------- 21 STILL WRONG */
{ const s=light(); chip(s,'04  THE HONEST PART');
  title(s,'What is still wrong.');
  const o=[['No screen-reader user has tested this.','Every accessibility claim is machine or browser verified, which isn\'t the same as a person using it. One session with somebody who uses one daily is worth more than the next five features.'],
           ['The agent’s narration is nondeterministic.','It rewrites what an action returns rather than relaying it. Three separate fixes didn\'t move it.'],
           ['Text and voice run through a relay on a laptop.','The number answers through a small relay beside the org. When it\'s down, the number goes quiet rather than replying wrongly. Hosting it is the first real deployment task.'],
           ['Slack, text and voice all live on one laptop.','The Slack app is installed in a real workspace and answers over Socket Mode, but it runs beside the relay. When the laptop sleeps, three channels go quiet at once.']];
  o.forEach(([t,d],i)=>{ const y=1.95+i*1.05;
    T(s,{t,o:{x:ML,y,w:4.5,h:0.45,fontSize:13.5,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x:5.5,y,w:6.95,h:0.95,fontSize:11.5,fontFace:B,color:SOFT}});
  });
  kicker(s,'A system that claims a perfect score against its own adversarial suite is telling you about its suite, not its agent.');
}

divider('05','The offer','Why this hasn\'t happened, and why that is over.');

/* ------------------------------------------------------- 22a THE REASONS */
{ const s=light(); chip(s,'05  THE OFFER');
  title(s,'Why good employers haven\'t done this.');
  const R=[['No budget line says "the asking was too hard."','The cost is real and has never been priced, so it has never been funded. You can\'t get money for a problem with no line item.'],
           ['Nobody owns it.','HR owns the policy. IT owns the systems. The manager owns the person. The request falls in the gap between three desks and waits there.'],
           ['Caution looks like safety.','Handling a disclosure badly carries legal risk, so doing nothing feels safest. It isn\'t safer, only quieter.'],
           ['The demand is invisible by design.','Three people in a hundred tell you. An empty queue reads as a solved problem, and the silence is taken as evidence.'],
           ['Every tool assumed disclosure first.','HR systems start from a diagnosis field. Building one without it meant building something new, and nobody had.']];
  R.forEach(([t,d],i)=>{ const y=1.90+i*0.85;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:0.055,h:0.70,fill:{color:GOLDFILL},line:{color:GOLDFILL,width:0}});
    T(s,{t,o:{x:1.1,y:y+0.02,w:4.7,h:0.58,fontSize:13,bold:true,fontFace:H,color:INK}});
    T(s,{t:d,o:{x:6.05,y:y+0.02,w:6.4,h:0.68,fontSize:11.5,fontFace:B,color:SOFT}});
  });
  kicker(s,'None of this was malice, and each one was a reason. From today, none of them is an excuse, because the thing exists, it\'s open, and it costs nothing to try.');
}

/* --------------------------------------------------------- 22b THE OFFER */
{ const s=light(); chip(s,'05  THE OFFER');
  title(s,'Free for the first ten. Here is the price.');

  s.addShape(p.ShapeType.roundRect,{x:ML,y:1.92,w:5.55,h:3.55,rectRadius:0.05,
    fill:{color:SURF},line:{color:GREEN,width:1.5}});
  T(s,{t:'What you get',o:{x:1.12,y:2.12,w:5.0,h:0.36,fontSize:15,bold:true,fontFace:H,color:GREEN}});
  T(s,{t:[{text:'The whole system, at no cost',options:{bullet:true,breakLine:true}},
          {text:'The code, and the library with every row\u2019s source',options:{bullet:true,breakLine:true}},
          {text:'The deployment into your own org, which holds your data, not ours',options:{bullet:true,breakLine:true}},
          {text:'Both audits, so you can check us rather than trust us',options:{bullet:true,breakLine:true}},
          {text:'No licence, no seat count, no lock-in',options:{bullet:true}}],
    o:{x:1.12,y:2.62,w:5.0,h:2.7,fontSize:12.5,fontFace:B,color:INK,paraSpaceAfter:9}});

  s.addShape(p.ShapeType.roundRect,{x:6.9,y:1.92,w:5.55,h:3.55,rectRadius:0.05,
    fill:{color:SURF},line:{color:INK,width:1.5}});
  T(s,{t:'What we ask instead of money',o:{x:7.17,y:2.12,w:5.0,h:0.36,fontSize:15,bold:true,fontFace:H,color:INK}});
  T(s,{t:[{text:'Name one owner. A person, not a department',options:{bullet:true,breakLine:true}},
          {text:'Answer within five working days. The wait is the cost',options:{bullet:true,breakLine:true}},
          {text:'Publish what you said yes to, in aggregate, with no names',options:{bullet:true,breakLine:true}},
          {text:'Let a disabled employee test it before you launch it',options:{bullet:true,breakLine:true}},
          {text:'Tell us what broke',options:{bullet:true}}],
    o:{x:7.17,y:2.62,w:5.0,h:2.7,fontSize:12.5,fontFace:B,color:INK,paraSpaceAfter:9}});

  T(s,{t:'We aren\'t asking for a case study or a logo. Those five things are what actually makes an accommodation arrive, and an organisation unwilling to do them wouldn\'t have got value from the software either.',
    o:{x:ML,y:5.56,w:11.6,h:0.62,fontSize:13.5,fontFace:B,color:SOFT}});
  kicker(s,'Sixty-one in a hundred cost nothing. The first ten will find that out on their own data, in public, and then nobody gets to say it was the money.');
}

divider('A','Appendix','Every figure, its source, and the command that proves it.');

/* ------------------------------------------------------- 22c THE SOURCES */
{ const s=light(); chip(s,'APPENDIX  |  SOURCES');
  title(s,'Every figure, and where it came from.');
  const rows=[['1.3 billion, 16% of the world','WHO, Global report on health equity for persons with disabilities, 2022'],
              ['27% of Canadians aged 15+','Statistics Canada, Canadian Survey on Disability'],
              ['35.4% have an unmet need','Statistics Canada, the strongest single figure in this deck'],
              ['22.8% employed, against 65.2%','US Bureau of Labor Statistics, 2025'],
              ['30% have one, 3.2% tell','Coqual, US college-educated white-collar workers'],
              ['83% of those who told say it helped','Coqual, same study'],
              ['61% of accommodations cost nothing','Job Accommodation Network, 1,425 employers through 2024']];
  rows.forEach(([f,src_],i)=>{ const y=1.92+i*0.60;
    s.addShape(p.ShapeType.rect,{x:ML,y,w:4.5,h:0.52,fill:{color:SUNK},line:{color:LINE,width:1}});
    T(s,{t:f,o:{x:ML+0.16,y:y+0.15,w:4.2,h:0.3,fontSize:12,bold:true,fontFace:B,color:INK}});
    T(s,{t:src_,o:{x:5.6,y:y+0.15,w:6.9,h:0.34,fontSize:11.5,fontFace:B,color:SOFT}});
  });
  kicker(s,'They narrow rather than contradict. The wider the definition, the more people find they are counted, and the more of them have never told anyone at work.');
}

/* -------------------------------------------------------- 22d HOW TO CHECK */
{ const s=light(); chip(s,'APPENDIX  |  VERIFICATION');
  title(s,'Don\'t take any of it on trust.');
  const cmd=[['508','structural invariants','python3 tests/invariants.py'],
             ['124','Apex tests','sf apex run test -o curbcut -l RunLocalTests'],
             ['333','accessibility checks, live pages','python3 tests/a11y_audit.py'],
             ['131','Sa11y, Salesforce\u2019s own matcher','npm run test:a11y'],
             ['21','responsible AI checks','python3 tests/rai_self_check.py'],
             ['28','contrast checks, both themes','python3 tests/contrast_audit.py'],
             ['21/23','adversarial assertions, deliberately not 23','node tests/headless_agent_api.mjs']];
  cmd.forEach(([n,d,c],i)=>{ const y=1.92+i*0.60;
    T(s,{t:n,o:{x:ML,y:y+0.06,w:1.0,h:0.36,fontSize:16,bold:true,fontFace:M,color:GOLD,align:'right'}});
    T(s,{t:d,o:{x:2.05,y:y+0.12,w:4.2,h:0.32,fontSize:12,fontFace:B,color:INK}});
    s.addShape(p.ShapeType.rect,{x:6.35,y,w:6.1,h:0.48,fill:{color:SUNK},line:{color:LINE,width:1}});
    T(s,{t:c,o:{x:6.52,y:y+0.15,w:5.8,h:0.3,fontSize:10.5,fontFace:M,color:INK}});
  });
  kicker(s,'Nothing in this deck is asserted from memory. Every figure was read from the deployed org, or from the run that produced it.');
  src(s,'Org 00DgK00000YIJ5SUAX   ·   Curb_Cut v7 and Curb_Cut_Desk v5, both Active   ·   github.com/parthsevak2/curb-cut');
}

/* -------------------------------------------------------------- 22 CLOSE */
{ const s=deep();
  T(s,{t:'You already know what it costs to ask.',o:{x:ML,y:1.85,w:11.3,h:0.9,
    fontSize:38,bold:true,fontFace:H,color:PAPER}});
  T(s,{t:'You felt it in the small version, over a chair or an hour. Nobody should have to prove anything to get those, and nobody should have to spend themselves asking.',
    o:{x:ML,y:2.95,w:10.8,h:1.0,fontSize:18,fontFace:B,color:'D8DAD6'}});
  T(s,{t:'They only have to be able to ask.',o:{x:ML,y:4.2,w:10.5,h:0.7,fontSize:25,
    fontFace:H,italic:true,color:GOLDLT}});
  T(s,{t:'Verify anything in this deck:',o:{x:ML,y:5.3,w:6,h:0.35,fontSize:11.5,fontFace:M,color:DIMTX}});
  T(s,{t:'python3 tests/invariants.py          508 checks\nsf apex run test -l RunLocalTests     137 tests\npython3 tests/a11y_audit.py          333 checks, against the live pages',
    o:{x:ML,y:5.62,w:8.5,h:1.0,fontSize:10.5,fontFace:M,color:'D8DAD6'}});
  T(s,{t:'orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut',o:{x:ML,y:6.75,w:11,h:0.35,
    fontSize:11.5,fontFace:M,color:DIMTX}});
  s.addNotes('Land on "They only have to be able to ask." Then stop.');
}

p.writeFile({fileName:'Curb-Cut.pptx'}).then(f=>console.log('wrote',f));

/* pptxgenjs writes every part STORED rather than DEFLATED, which made a deck of
   plain text slides 384KB. Recompressing the same bytes takes it to 83KB. */
