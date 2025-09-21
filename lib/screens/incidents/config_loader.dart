// lib/utils/config_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigLoader {
  static Map<String, dynamic>? _config;
  
  static Future<Map<String, dynamic>> loadConfig() async {
    if (_config != null) return _config!;
    
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/config/incident_analysis_config.json'
      );
      
      _config = json.decode(jsonString);
      return _config!;
    } catch (e) {
      print('Error loading config: $e');
      // Return default config if file loading fails
      return _getDefaultConfig();
    }
  }
  
  static Map<String, dynamic> _getDefaultConfig() {
    return {
      "analysisRules": {
        "suspiciousPatterns": {
          "english": [
            "fake", "test", "joke", "prank", "not real", "false", "drill",
            "just kidding", "not serious", "practice report", "test lang",
            "no emergency", "just a drill", "this is only a test", "exercise",
            "simulation", "mock", "bullshit", "nonsense", "lie", "lying",
            "made up", "fabricated", "not true", "just practicing", "trial",
            "experiment", "hypothetical", "pretend", "fiction", "not actual",
            "false alarm", "only testing", "just checking", "system test",
            "app test", "trying out", "experimental", "demo", "sample",
            "placeholder", "dummy", "mockup", "prototype", "trial run"
          ],
          "filipino": [
            "biro", "sinubukan", "walang totoo", "peke", "gago", "bobo",
            "tang ina", "putang ina", "leche", "punyeta", "sira ulo",
            "walang", "tunay", "totoo", "ensayo", "pagsasanay", "praktek",
            "nagpapanggap", "hindi totoo", "kasinungalingan", "gawa-gawa",
            "panggap", "laruan", "lokohan", "biruan", "pambobola", "bolero",
            "sinungaling", "daya", "linlang", "panloloko", "panggagago",
            "trial", "eksperimento", "subok", "pakunwari", "kunwari", 
            "putangina", "tangina", "puta", "pota"
          ]
        },
        "inappropriateLanguage": {
          "english": [
            // Profanity and vulgar language
            "fuck", "shit", "asshole", "bastard", "bitch", "cunt", "dick",
            "piss", "crap", "damn", "hell", "retard", "idiot", "moron",
            "stupid", "dumb", "whore", "slut", "fag", "faggot", "pussy",
            "cock", "ass", "arse", "bullshit", "motherfucker", "shithead",
            "dickhead", "douchebag", "scumbag", "shitface", "fuckface",
            "shitbag", "asswipe", "dipshit", "shitforbrains", "fuckwit",
            "cocksucker", "wanker", "twat", "bellend", "prick", "dickwad",
            "shitstain", "asshat", "fuckoff", "fuckyou", "screwyou",
            
            // Racial and discriminatory slurs
            "nigger", "nigga", "chink", "gook", "spic", "kike", "wetback",
            "cracker", "redneck", "white trash", "sandnigger", "towelhead",
            "raghead", "beaner", "slanteye", "halfbreed", "mulatto",
            "oreo", "zipperhead", "junglebunny", "porchmonkey", "coon",
            
            // Ableist language
            "retard", "retarded", "spaz", "cripple", "lame", "mental",
            "psycho", "schizo", "retardation", "handicapped", "disabled",
            
            // Gender-based insults
            "bitch", "slut", "whore", "cunt", "hoe", "thot", "skank",
            "tramp", "harlot", "hussy", "strumpet", "tart", "slag"
          ],
          "filipino": [
            // Common Filipino profanity
            "gago", "bobo", "tang ina", "putang ina", "leche", "punyeta",
            "sira ulo", "ulol", "baliw", "lintik", "demonyo", "hayop",
            "potang ina", "pakshet", "pucha", "burat", "tarantado", "unggoy",
            "babaero", "pokpok", "kerida", "walang hiya", "puta", "putahe",
            "kupal", "gagu", "bwisit", "bwiset", "shet", "pakyu", "pakyaw",
            "tanga", "engot", "ungas", "bangag", "sira", "siraulo",
            "lintik", "demonyo", "impakto", "aswang", "tikbalang",
            
            // Derogatory terms
            "ampon", "anak sa labas", "bastardo", "bilat", "kantot",
            "kantutan", "kepyas", "kiki", "kinakantot", "manyak",
            "manyakis", "obob", "ogag", "pakingshet", "pakshet", "peste",
            "pisti", "puking", "pukingina", "punyeta", "putragis",
            "putris", "salsal", "salsalan", "sira", "siraulo", "supot",
            "tamod", "tanga", "tarantado", "tete", "timang", "tite",
            "totnak", "tungaw", "ugok", "ulol", "ungas", "ungol",
            
            // Gender-based insults
            "bakla", "tomboy", "binabae", "bayot", "bading", "silahis",
            "tibo", "tita", "binabae", "agui", "bantut", "beki", "billy",
            "duda", "jokla", "kiri", "laki", "parlorista", "sward",
            "tita", "tito", "trans", "trapo"
          ]
        },
        "disrespectfulContent": {
          "english": [
            // Disrespect and harassment
            "kill yourself", "go die", "you should die", "drop dead",
            "nobody likes you", "everyone hates you", "you're worthless",
            "you're useless", "you're pathetic", "you're garbage",
            "you're trash", "you're nothing", "you're a mistake",
            "you're a failure", "worthless piece", "useless piece",
            "piece of shit", "piece of garbage", "human waste",
            "waste of space", "waste of oxygen", "disgusting human",
            "disgusting person", "rot in hell", "burn in hell",
            "go to hell", "fuck off", "get lost", "nobody wants you",
            "nobody cares", "kill yourself", "end your life",
            "commit suicide", "self harm", "cut yourself", "hurt yourself",
            
            // Threats and intimidation
            "i'll kill you", "i'll hurt you", "i'll beat you",
            "i'll find you", "i'll get you", "watch your back",
            "you're dead", "you're finished", "i'm coming for you",
            "prepare to die", "your days are numbered", "i'll destroy you",
            "i'll ruin you", "i'll expose you", "i'll report you",
            "i'll make you pay", "you'll regret this", "you'll pay for this",
            
            // Bullying and demeaning
            "loser", "failure", "reject", "outcast", "freak", "weirdo",
            "creep", "stalker", "psycho", "mental case", "nutjob",
            "weirdo", "freakshow", "abomination", "monster", "animal",
            "beast", "savage", "primitive", "uncivilized", "barbarian"
          ],
          "filipino": [
            // Filipino disrespectful phrases
            "mamatay ka na", "kamatayan mo", "magpakamatay ka",
            "wala kang kwenta", "walang silbi", "basura kang tao",
            "taong grasa", "estranghero", "dayuhan", "di kanais-nais",
            "kadiri", "nakakadiri", "suklam", "nakakasuka", "suka",
            "pangit", "pangit mo", "ang pangit mo", "ang baho mo",
            "mabaho", "amoy pawis", "amoy alimuom", "amoy basura",
            "amoy kulob", "amoy patay", "amoy lansa", "amoy usok",
            
            // Threats and intimidation
            "papatayin kita", "sasaktan kita", "hahampasin kita",
            "gugulpiin kita", "babugbogin kita", "babatukan kita",
            "sasampalin kita", "ipapahiya kita", "isisigaw kita",
            "ipagkakalat kita", "kakalatin kita", "wawasakin kita",
            "gigipitin kita", "aawayin kita", "lalabanan kita",
            
            // Bullying and demeaning
            "bobo", "tanga", "engot", "gunggong", "ungas", "bangag",
            "siraulo", "ulol", "baliw", "loko", "loko-loko", "sira",
            "may sayad", "may topak", "may sira", "abnoy", "abnormal",
            "baliw", "sukab", "taksil", "traidor", "plastik", "ipokrito",
            "sinungaling", "mandaraya", "manloloko", "magnanakaw",
            "kupit", "daya", "linlang"
          ]
        },
        "lustfulContent": {
          "english": [
            // Explicit sexual content
            "fuck me", "fuck you", "have sex", "make love", "sleep with",
            "hook up", "one night stand", "blowjob", "bj", "handjob",
            "hj", "oral sex", "anal sex", "doggy style", "missionary",
            "69", "orgy", "threesome", "gangbang", "bdsm", "sadomasochism",
            "dominant", "submissive", "master", "slave", "bondage",
            "restraint", "choke", "spank", "whip", "kink", "fetish",
            "roleplay", "cosplay", "strip", "naked", "nude", "bare",
            "expose", "flash", "show me", "send nudes", "nudes",
            "dick pic", "pussy pic", "boobs", "tits", "breasts",
            "ass", "butt", "booty", "cock", "dick", "penis", "pussy",
            "vagina", "clit", "clitoris", "cum", "semen", "jizz",
            "ejaculate", "masturbate", "jerk off", "jack off", "rub",
            "touch", "feel", "finger", "lick", "suck", "bite", "kiss",
            "moan", "groan", "scream", "wet", "horny", "aroused",
            "turned on", "hard", "erection", "hard on", "boner",
            "wet", "moist", "lubricate", "lube", "condom", "protection",
            "birth control", "pill", "iud", "implant", "vasectomy",
            "sterilization", "pregnant", "pregnancy", "condom broke",
            "std", "sti", "hiv", "aids", "herpes", "syphilis",
            "gonorrhea", "chlamydia", "hpv", "hepatitis", "trichomoniasis"
          ],
          "filipino": [
            // Filipino explicit content
            "kantot", "kantutan", "tira", "tirahan", "jakol", "jakulan",
            "tamod", "tamudan", "libog", "malibog", "manyak", "manyakis",
            "halay", "mahalay", "bastos", "malaswa", "walang hiya",
            "hubad", "huwag", "hubaran", "hubarin", "tanggal", "tanggalan",
            "alis", "alisan", "hubo", "hubuan", "hubadero", "hubadera",
            "bold", "nagbo-bold", "sexy", "poging", "gandang", "pogi",
            "ganda", "gwapo", "maganda", "pabebe", "pa-cute", "pa-sexy",
            "pa-tweetums", "pa-fall", "pa-asa", "pa-uto", "pa-sweet",
            "landi", "malandi", "flirt", "flirtahan", "ligaw", "manligaw",
            "liligawan", "date", "idate", "kadate", "kasama", "kasamahan",
            "tropa", "tropahan", "barkada", "barkadahan", "inuman",
            "tagay", "tagayan", "shot", "shot puno", "lasheng", "lasing",
            "nalasing", "lasingan", "gimik", "gimikan", "disco", "bar",
            "club", "inuman", "spakol", "massage", "masahe", "masahista",
            "extra", "extra service", "happy ending", "es", "full service",
            "fs", "short time", "st", "overnight", "on", "take out",
            "to", "service", "serbisyo", "bayad", "bayaran", "presyo",
            "rate", "package", "pakete", "all in", "ai", "with room",
            "may room", "motel", "short time hotel", "st hotel", "love hotel",
            "inn", "pension", "apartment", "apartment for rent", "apa",
            "condo", "condominium", "transient", "transient house",
            "bed spacer", "bed space", "boarding house", "dormitory",
            "dorm", "room for rent", "room rent"
          ]
        },
        "implausibleScenarios": [
          "alien invasion", "zombie attack", "superhero sighting",
          "magical event", "fantasy creature", "impossible physics",
          "time travel", "teleportation", "flying car", "talking animal",
          "unicorn", "dragon", "vampire", "werewolf", "ghost", "spirit",
          "demon", "angel", "ufo", "extraterrestrial", "bigfoot",
          "loch ness", "yeti", "sasquatch", "levitation", "invisibility",
          "superpower", "x-ray vision", "mind reading", "telepathy",
          "telekinesis", "psychic", "fortune telling", "prophecy",
          "miracle", "divine intervention", "magic trick", "illusion",
          "hallucination", "dream", "nightmare", "fantasy", "fiction",
          "myth", "legend", "fairy tale", "comic book", "movie plot",
          "video game", "virtual reality", "simulation", "matrix",
          "alternate reality", "parallel universe", "multiverse"
        ],
        "vagueDescriptions": [
          "something happened", "you know what", "that thing",
          "over there", "somewhere around", "I don't know exactly",
          "can't remember", "not sure", "whatever", "etc.", "and so on",
          "and stuff", "and things", "blah blah", "yada yada",
          "you know", "like whatever", "sort of", "kind of", "maybe",
          "perhaps", "possibly", "probably", "I think", "I believe",
          "I guess", "I suppose", "around", "about", "approximately",
          "roughly", "some", "several", "a few", "a couple", "many",
          "lots", "bunch", "group", "people", "persons", "individuals",
          "someone", "somebody", "anyone", "anybody", "no one", "nobody",
          "everyone", "everybody", "something", "anything", "nothing",
          "everything", "somewhere", "anywhere", "nowhere", "everywhere",
          "sometime", "anytime", "never", "always", "often", "sometimes",
          "usually", "rarely", "seldom", "frequently", "occasionally"
        ]
      },
      "scoringCriteria": {
        "highSuspicion": {
          "threshold": 0.7,
          "indicators": [
            "Multiple explicit false report statements",
            "Offensive or inappropriate language",
            "Clearly impossible scenarios",
            "Contradictory information",
            "Explicit sexual content",
            "Threats or harassment",
            "Hate speech or discrimination"
          ]
        },
        "mediumSuspicion": {
          "threshold": 0.4,
          "indicators": [
            "Single false report indicator",
            "Mildly inappropriate language",
            "Vague or incomplete details",
            "Somewhat implausible scenario",
            "Suggestive content",
            "Mild disrespect"
          ]
        },
        "lowSuspicion": {
          "threshold": 0.1,
          "indicators": [
            "Minor language concerns",
            "Slightly vague details",
            "Possible but unlikely scenario",
            "Ambiguous phrasing"
          ]
        }
      }
    };
  }
  
  static List<String> getAllSuspiciousPatterns() {
    final patterns = _config?['analysisRules']['suspiciousPatterns'] ?? _getDefaultConfig()['analysisRules']['suspiciousPatterns'];
    final List<String> allPatterns = [];
    allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
    allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
    return allPatterns;
  }

  static List<String> getAllInappropriateLanguage() {
    final patterns = _config?['analysisRules']['inappropriateLanguage'] ?? _getDefaultConfig()['analysisRules']['inappropriateLanguage'];
    final List<String> allPatterns = [];
    allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
    allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
    return allPatterns;
  }

  static List<String> getAllDisrespectfulContent() {
    final patterns = _config?['analysisRules']['disrespectfulContent'] ?? _getDefaultConfig()['analysisRules']['disrespectfulContent'];
    final List<String> allPatterns = [];
    allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
    allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
    return allPatterns;
  }

  static List<String> getAllLustfulContent() {
    final patterns = _config?['analysisRules']['lustfulContent'] ?? _getDefaultConfig()['analysisRules']['lustfulContent'];
    final List<String> allPatterns = [];
    allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
    allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
    return allPatterns;
  }

  static List<String> getAllImplausibleScenarios() {
    return _config?['analysisRules']['implausibleScenarios'] ?? _getDefaultConfig()['analysisRules']['implausibleScenarios'];
  }

  static List<String> getAllVagueDescriptions() {
    return _config?['analysisRules']['vagueDescriptions'] ?? _getDefaultConfig()['analysisRules']['vagueDescriptions'];
  }
}