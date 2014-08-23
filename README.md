# Simple Google™ TTS

## Description

This project hosts a bash wrapper for [Michal Fapso's `speak.pl` script](https://gist.github.com/michalfapso/3110049).

The intention is to provide an easy to use interface to text-to-speech output via Google's speech synthesis system. A fallback option using `pico2wave` automatically provides TTS synthesis in case no Internet connection is found.

As it stands, the wrapper supports reading from standard input, plain text files and the X selection (highlighted text).

Please note that `speak.pl` and, in turn, this script use an ["unofficial Google TTS API"](http://weston.ruter.net/2009/12/12/google-tts/), which has several limitations. `simple_google_tts` and `speak.pl` try to work around some of these problems, e.g. "API" requests being limited to 100 characters, but are subject to other restrictions, e.g. obligatory CAPTCHA input for overly frequent requests. As a result, your experience may vary.

## Why use this wrapper?

*Warning: What follows is a technical explanation of the inner workings of `speak.pl` and this wrapper. You don't have to read this to understand how to use this project but it can help shed some light on the issues you might experience.*

Google imposes a 100-character limit on their speech synthesis service that makes it impossible to use their TTS system for anything longer than a short sentence. `speak.pl` works around this limitation by breaking the text input down into appropriate chunks. The chunk cut-offs are set intelligently based on the punctuation and syntax of the input text. Having processed all chunks `speak.pl` then concatenates the speech fragments into one `mp3` file while truncating segments of silence at the start and end of each fragment.

All of these processing steps ensure a relatively natural voice output and minimize the number of clunky pauses caused by the 100-character limitation.

However, the main problem with this approach is that the waiting time between user input and voice playback scales linearly with the length of the text. This is where `simple_google_tts` comes in:

Instead of passing the complete input text to `speak.pl`, `simple_google_tts` first breaks down the input into paragraphs. The paragraphs are then processed one after another with each paragraph being played back while the next one is synthesized. This way any length of text can be parsed with reasonable speed.

`simple_google_tts` also adds automatic playback, more input modes, an offline TTS back end, and several adjustments that make it possible to parse documents with fixed formatting (e.g. [selected text in PDF files](http://superuser.com/a/796341/170160)).

All of this could probably be accomplished a lot more elegantly within the original perl script, but I am not familiar with perl. So I had to make do with bash.

## Installation and dependencies

The following instructions are provided for Debian/Ubuntu based systems.

### Dependencies

**Overview of all dependencies**

You can install all dependencies with the following command:

    sudo apt-get install xsel libnotify-bin libttspico0 libttspico-utils libttspico-data libwww-perl libhtml-tree-perl sox libsox-fmt-mp3

A breakdown of the dependencies by component and role:

**Wrapper**

`xsel` provides support for parsing the X selection contents


`libnotify-bin` is used for GUI notifications


`pico2wave` provides the offline speech synthesis back end

The actual audio playback is handled by `sox`, which is part of `speak.pl`'s dependencies.

**speak.pl**

Dependencies, as listed in `speak.pl`'s header:

`libwww-perl libhtml-tree-perl sox libsox-fmt-mp3`

Perl should be part of your default Debian/Ubuntu installation.

### Installation

The installation is slightly overcomplicated right now. This is because `simple_google_tts` requires a few modifications to `speak.pl` to work (these are centered around disposal of temporary files).

Without knowing what license `speak.pl` ships with, I cannot include a modified copy in this repository. So, for the moment, you will have to apply my patch manually.

1. Clone this repository:
    
        git clone 

2. Download `speak.pl` from [Michal Fapso's gist](https://gist.github.com/michalfapso/3110049) and place it in the same directory as `simple_google_tts`:

        cd 
        git clone https://gist.github.com/3110049.git
        mv 3110049/speak.pl speak.pl && rm -r 3110049

3. Apply the provided patch to `speak.pl`:

        patch speak.pl < speakpl.patch

4. Make `speak.pl` executable

        chmod +x speak.pl

You should be able to run `simple_google_tts` now. If you wish you can symlink `simple_google_tts` to your `PATH` (e.g. `~/bin` or `/usr/local/bin`) to make it easier to access. 

`speak.pl` must always reside in the same directory as `simple_google_tts`.

## Usage

### General usage

    simple_google_tts <options> <languagecode> <input>

E.g.:

    $ simple_google_tts -g en "Hello world."
    Reading from string.
    Using Google for TTS synthesis.
    Synthesizing virtual speech.
    Processing 1 out of 2 paragraphs
    Playing synthesized speech 1
    Processing 2 out of 2 paragraphs
    Skipping empty paragraph
    All sections processed. Waiting for playback to finish.

### Detailed explanation

`simple_google_tts` can read text from standard input or a text file. The syntax is the same in each case. The wrapper will automatically identify the type of input provided and perform the text to speech synthesis via `speak.pl`.

If no arguments are provided `simple_google_tts` will try to read from the current X selection. This corresponds with the currently highlighted text. Using this functionality you can set up a keyboard shortcut that automatically reads out selected text.


At all times you can access an overview of all supported options by invoking the help output:

    $ simple_google_tts -h
    simple_google_tts [-p|-g|-h] languagecode ['strings'|'file.txt']

        -p:   use offline TTS (pico2wave) instead of Google's TTS system
        -g:   activate gui notifications (via notify-send)
        -h:   display this help section

        Selection of valid language codes: en, es, de...
        Check speak.pl for a list of all valid codes

        Warning: offline TTS only supports en, de, es, fr, it

        If an instance of the script is already running it will be terminated.

        If you don't provide an input string or input file, simple_google_tts
        will read from the X selection (current/last highlighted text)

### Options

- `-p`: By default `simple_google_tts` will use `speak.pl` to query Google's speech synthesis service and only fall back to `pico2wave` if no Internet connection is found. If you don't want to use Google's TTS service you can use this option to default to `pico2wave` speech synthesis.
- `-g`: If you plan to assign `simple_google_tts` to a keyboard shortcut you can use this option to enable GUI notifications using `libnotify-bin` (the default notification daemon).
- `-h`: Display help section

### Supported languages

**Google TTS**

Google's TTS service currently supports the following language codes:

    af  Afrikaans
    sq  Albanian
    am  Amharic
    ar  Arabic
    hy  Armenian
    az  Azerbaijani
    eu  Basque
    be  Belarusian
    bn  Bengali
    bh  Bihari
    bs  Bosnian
    br  Breton
    bg  Bulgarian
    km  Cambodian
    ca  Catalan
    zh-CN Chinese (Simplified)
    zh-TW Chinese (Traditional)
    co  Corsican
    hr  Croatian
    cs  Czech
    da  Danish
    nl  Dutch
    en  English
    eo  Esperanto
    et  Estonian
    fo  Faroese
    tl  Filipino
    fi  Finnish
    fr  French
    fy  Frisian
    gl  Galician
    ka  Georgian
    de  German
    el  Greek
    gn  Guarani
    gu  Gujarati
    ha  Hausa
    iw  Hebrew
    hi  Hindi
    hu  Hungarian
    is  Icelandic
    id  Indonesian
    ia  Interlingua
    ga  Irish
    it  Italian
    ja  Japanese
    jw  Javanese
    kn  Kannada
    kk  Kazakh
    rw  Kinyarwanda
    rn  Kirundi
    ko  Korean
    ku  Kurdish
    ky  Kyrgyz
    lo  Laothian
    la  Latin
    lv  Latvian
    ln  Lingala
    lt  Lithuanian
    mk  Macedonian
    mg  Malagasy
    ms  Malay
    ml  Malayalam
    mt  Maltese
    mi  Maori
    mr  Marathi
    mo  Moldavian
    mn  Mongolian
    sr-ME Montenegrin
    ne  Nepali
    no  Norwegian
    nn  Norwegian (Nynorsk)
    oc  Occitan
    or  Oriya
    om  Oromo
    ps  Pashto
    fa  Persian
    pl  Polish
    pt-BR Portuguese (Brazil)
    pt-PT Portuguese (Portugal)
    pa  Punjabi
    qu  Quechua
    ro  Romanian
    rm  Romansh
    ru  Russian
    gd  Scots Gaelic
    sr  Serbian
    sh  Serbo-Croatian
    st  Sesotho
    sn  Shona
    sd  Sindhi
    si  Sinhalese
    sk  Slovak
    sl  Slovenian
    so  Somali
    es  Spanish
    su  Sundanese
    sw  Swahili
    sv  Swedish
    tg  Tajik
    ta  Tamil
    tt  Tatar
    te  Telugu
    th  Thai
    ti  Tigrinya
    to  Tonga
    tr  Turkish
    tk  Turkmen
    tw  Twi
    ug  Uighur
    uk  Ukrainian
    ur  Urdu
    uz  Uzbek
    vi  Vietnamese
    cy  Welsh
    xh  Xhosa
    yi  Yiddish
    yo  Yoruba
    zu  Zulu 

Please note that, out of these, the `pico2wave` back end only supports the following languages:

    en  English
    de  German
    es  Spanish
    fr  French
    it  Italian

### More examples

**Read English text from file**

    simple_google_tts en readme.md

**Read from X selection, using pico2wave, and enable notifications**

    simple_google_tts -gp en

## Known issues

- to prevent simultaneous output the wrapper tries to force only one instance at a time. Unfortunately this fails sometimes, which can be a problem when using the script through a keyboard shortcut

- there is no easy way to terminate the TTS output if the script is used via a keyboard shortcut. 
  
    Highlighting an empty line or space and then executing the script should, in theory, terminate the last script instance and stop the playback. Because of the first issue this does not always work.

    You could probably assign another hotkey to terminate any running instances of the script (e.g. `pkill -9 simple_google_tts`; warning: I have yet to try this out).

- too many requests in too short an amount of time will cause Google to start requesting CAPTCHA input. At this point the Google TTS backend of the script basically becomes useless. Note: I have yet to hit this limit in my regular usage. 

## License

The script and all other project files are licensed under the [GNU GPLv3](http://www.gnu.de/documents/gpl-3.0.en.html). `simple_google_tts` is not endorsed, certified or otherwise approved in any way by Google™.