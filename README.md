## Status update

**This project is currently unmaintained and will remain so for the foreseeable future**. 

This script and many others like it rely on an unofficial API that has recently become increasingly difficult to support. As Google continues to lock down access to their TTS interface I see no choice other than to suspend maintaining this script for the time being. I sincerely hope that the future will see an official way to use Google TTS on desktop Linux. Until then, please feel free to fork this project if you want to try to fix it.

As a last note: Make sure to also check out the [section on similar projects](https://github.com/Glutanimate/simple-google-tts#similar-projects) provided in this README.

----------------------------

# Simple Google™ TTS

Ever wanted to use Google text-to-speech on Linux? Now you can.

## Table of Contents

<!-- MarkdownTOC -->

- [Description](#description)
- [Why use this script?](#why-use-this-script)
- [Installation and dependencies](#installation-and-dependencies)
    - [Dependencies](#dependencies)
    - [Installation](#installation)
- [Usage](#usage)
    - [General usage](#general-usage)
    - [Detailed explanation](#detailed-explanation)
    - [Options](#options)
    - [Supported languages](#supported-languages)
    - [More examples](#more-examples)
- [Known issues](#known-issues)
- [Similar projects](#similar-projects)
- [License](#license)

<!-- /MarkdownTOC -->

## Description

The intent of this project is to provide an easy way to use text-to-speech output by Google on your Linux desktop. The script supports reading from standard input, plain text files, and highlighted text. A fall-back interface based on `pico2wave` takes care of the TTS output when you are offline. 

----

`simple-google-tts` is based on [`speak.pl` by Michal Fapso](http://michalfapso.blogspot.de/2012/01/using-google-text-to-speech.html) which uses an [unofficial Google TTS API](http://weston.ruter.net/2009/12/12/google-tts/). This results in several limitations. `simple_google_tts` and `speak.pl` try to work around some of these issues, e.g. requests being limited to 100 characters, but are subject to other restrictions, e.g. obligatory CAPTCHA input for overly frequent requests. Please keep this in mind when using this project.

## Why use this script?

*Note: What follows is a technical explanation of the inner workings of `speak.pl` and `simple_google_tts`. You don't have to read this to understand how to use this program, but it can help shed some light on the issues you might experience.*

Google imposes a 100-character limit on their speech synthesis service that makes it hard to use their TTS system for anything other than short sentences.

`speak.pl` works around this limitation by breaking the text input down into appropriate chunks. These chunks are set intelligently based on punctuation and syntax of the text. Having processed all chunks `speak.pl` then concatenates the speech fragments into one audio file while truncating segments of silence at the start and end of each fragment.

All of these processing steps ensure a relatively natural voice output and minimize the number of clunky pauses caused by the 100-character limitation. The one remaining problem with this approach is that the waiting time between user input and voice playback scales drastically with the length of the text. 

This is where `simple_google_tts` comes in: Instead of passing the text directly to `speak.pl`, `simple_google_tts` first breaks down the input into paragraphs. The paragraphs are then processed one by one with each paragraph being played back while the next one is synthesized. Any length of text can be parsed with reasonable speed in this manner.

Additionally, `simple_google_tts` includes automatic playback, more input modes, an offline TTS back-end, and several adjustments that facilitate parsing of documents with fixed formatting (e.g. [selected text in PDF files](http://superuser.com/a/796341/170160)).

All of this could have probably been accomplished a lot more elegantly within the original `speak.pl` script, but I am not familiar with perl.

## Installation and dependencies

The following instructions are provided for Debian/Ubuntu based systems.

### Dependencies

**Overview of all dependencies**

You can install all dependencies with the following command:

    sudo apt-get install xsel libnotify-bin libttspico0 libttspico-utils libttspico-data libwww-perl libwww-mechanize-perl libhtml-tree-perl sox libsox-fmt-mp3

A breakdown of the dependencies by component and role:

**simple_google_tts**

`xsel` provides support for parsing the X selection contents


`libnotify-bin` is used for GUI notifications


`pico2wave` provides the offline speech synthesis back-end

The actual audio playback is handled by `sox`, which is part of `speak.pl`'s dependencies.

**speak.pl**

Dependencies, as listed in `speak.pl`'s header:

`libwww-perl libwww-mechanize-perl libhtml-tree-perl sox libsox-fmt-mp3`

Perl should be part of your default Debian/Ubuntu installation.

### Installation

1. Install all dependencies

2. Clone this repository:
    
        git clone https://github.com/Glutanimate/simple-google-tts.git

3. Navigate to the download directory

        cd simple-google-tts

You should be able to run `./simple_google_tts` now. If you wish you can symlink `simple_google_tts` to your `PATH` (e.g. `~/bin` or `/usr/local/bin`) to make it easier to access. 

`speak.pl` must always reside in the same directory as `simple_google_tts`.

## Usage

### General usage

    simple_google_tts <options> <languagecode> <input>

E.g.:

    $ simple_google_tts en "Hello World"
    Reading from string.
    Using Google for TTS synthesis.
    Synthesizing virtual speech.
    Processing 1 out of 1 paragraphs
    Playing synthesized speech 1
    All sections processed. Waiting for playback to finish.

### Detailed explanation

`simple_google_tts` can read text from standard input or a text file. The syntax is the same in each case. The script will automatically identify the type of input provided and perform the text to speech synthesis via `speak.pl`.

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

Please note that, out of these, the `pico2wave` back-end only supports the following languages:

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

- to prevent simultaneous output the script tries to force only one instance at a time. Unfortunately this fails sometimes, which can be a problem when using the script through a keyboard shortcut

- there is no easy way to terminate the TTS output if the script is used via a keyboard shortcut. 
  
    Highlighting an empty line or space and then executing the script should, in theory, terminate the last script instance and stop the playback. Because of the first issue this does not always work.

    You could probably assign another hotkey to terminate any running instances of the script (e.g. `pkill -9 simple_google_tts`; warning: I have yet to try this out).

- too many requests too quickly will cause Google to start requesting CAPTCHA input. I have yet to hit this limit in my regular use of the script. 

## Similar projects

- [desbma/GoogleSpeech](https://github.com/desbma/GoogleSpeech)
- [pndurette/gTTS](https://github.com/pndurette/gTTS)

## License

*`speak.pl` copyright 2012 Michal Fapso*

*`simple_google_tts` copyright 2014 Glutanimate*

`simple_google_tts` is licensed under the [GNU GPLv3](http://www.gnu.de/documents/gpl-3.0.en.html). For licensing information concerning `speak.pl` please contact [Michal Fapso](https://github.com/michalfapso). 

This project is not endorsed, certified or otherwise approved in any way by Google™.