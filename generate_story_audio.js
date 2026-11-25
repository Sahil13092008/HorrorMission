const { MsEdgeTTS, OUTPUT_FORMAT } = require('C:/Users/sisod/OneDrive/Desktop/node_modules/msedge-tts');
const fs = require('fs');
const path = require('path');

const audioDir = 'C:/Users/sisod/OneDrive/Desktop/HorrorMission/audio';

const lines = [
    {
        filename: 'call_sahil_2.mp3',
        text: 'सब अपने-अपने गैजेट्स लेके बॉयज़ स्कूल पहुँचो, वहाँ आगे का प्लान बनाते हैं!',
        voice: 'hi-IN-MadhurNeural',
        pitch: '-8%',
        rate: '+6%',
        volume: '+30%'
    },
    {
        filename: 'call_aashu_2.mp3',
        text: 'हाँ भाई, मैं अपना सारा ईएमएफ और रिसर्च सामान बैग में पैक करके अपनी साइकिल से बॉयज़ स्कूल पहुँच रहा हूँ!',
        voice: 'hi-IN-MadhurNeural',
        pitch: '+4%',
        rate: '+8%',
        volume: '+30%'
    },
    {
        filename: 'call_player_3.mp3',
        text: 'ठीक है, मैं भी अपने सारे ज़रूरी गैजेट्स बैग में पैक करता हूँ और साइकिल लेके सीधे बॉयज़ स्कूल निकलता हूँ!',
        voice: 'hi-IN-MadhurNeural',
        pitch: '+1%',
        rate: '+5%',
        volume: '+30%'
    },
    {
        filename: 'pack_player_done.mp3',
        text: 'सारे ज़रूरी गैजेट्स बैग में पैक हो गए! अब बाहर से अपनी साइकिल लेकर तुरंत बॉयज़ स्कूल निकलता हूँ!',
        voice: 'hi-IN-MadhurNeural',
        pitch: '+1%',
        rate: '+5%',
        volume: '+30%'
    },
    {
        filename: 'school_sahil_arrival.mp3',
        text: 'अरे आ गया भाई! सब गैजेट्स और जरूरी सामान ले आया ना बैग में?',
        voice: 'hi-IN-MadhurNeural',
        pitch: '-8%',
        rate: '+6%',
        volume: '+30%'
    },
    {
        filename: 'school_player_arrival.mp3',
        text: 'हाँ भाई! टॉर्च, ईएमएफ डिटेक्टर, वॉकी-टॉकी और भानगढ़ के सारे नोट्स बैग में पैक हैं! तुम दोनों बताओ, क्या तैयारी है?',
        voice: 'hi-IN-MadhurNeural',
        pitch: '+1%',
        rate: '+5%',
        volume: '+30%'
    },
    {
        filename: 'school_aashu_arrival.mp3',
        text: 'मैंने सारा भानगढ़ का नक्शा, थर्मल सेंसर्स और एक्स्ट्रा बैटरियाँ पैक कर ली हैं। भानगढ़ के पुराने मुख्य द्वार के पास एक गुप्त रास्ता है, हमें वहीं से अंदर दाखिल होना होगा!',
        voice: 'hi-IN-MadhurNeural',
        pitch: '+4%',
        rate: '+8%',
        volume: '+30%'
    },
    {
        filename: 'school_sahil_plan.mp3',
        text: 'बिल्कुल सही! आज रात हमें किसी भी हाल में भानगढ़ खंडहर के अंदर जाकर कृपाल को तलाशना होगा! चलो, सीधे भानगढ़ के लिए निकलते हैं!',
        voice: 'hi-IN-MadhurNeural',
        pitch: '-8%',
        rate: '+6%',
        volume: '+30%'
    }
];

async function generateAll() {
    console.log('Generating updated dialogue audio files...');
    for (const item of lines) {
        console.log(`Generating: ${item.filename} [${item.text.substring(0, 30)}...]`);
        const tts = new MsEdgeTTS();
        await tts.setMetadata(item.voice, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);
        const outPath = path.join(audioDir, item.filename);
        
        await new Promise((resolve, reject) => {
            const { audioStream } = tts.toStream(item.text, {
                pitch: item.pitch,
                rate: item.rate,
                volume: item.volume
            });
            const writable = fs.createWriteStream(outPath);
            audioStream.pipe(writable);
            writable.on('finish', () => {
                const stats = fs.statSync(outPath);
                console.log(`✓ Saved ${item.filename} (${stats.size} bytes)`);
                resolve();
            });
            audioStream.on('error', reject);
            writable.on('error', reject);
        });
    }
    console.log('All audio files generated successfully!');
}

generateAll().catch(err => {
    console.error('Error generating audio:', err);
    process.exit(1);
});
