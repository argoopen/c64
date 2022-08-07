SOUND: {
    .var music = LoadSid("audio.sid")

    .pc = music.location
    .fill music.size, music.getData(i)

    Init: {
    }
}
