import Foundation

struct Phrase: Identifiable {
    let id = UUID()
    let english: String
    let spanish: String
    let phonetic: String
}

enum PhraseCategory: String, CaseIterable, Identifiable {
    case basics = "Polite Basics"
    case gettingAround = "Getting Around"
    case eatingDrinking = "Eating & Drinking"
    case shopping = "Shopping"
    case beach = "At the Beach"
    case wildlife = "Nature & Wildlife"
    case slang = "Catracho Slang"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .basics: return "hand.wave"
        case .gettingAround: return "car"
        case .eatingDrinking: return "fork.knife"
        case .shopping: return "bag"
        case .beach: return "beach.umbrella"
        case .wildlife: return "leaf"
        case .slang: return "flame"
        }
    }

    var phrases: [Phrase] {
        switch self {
        case .basics:
            return [
                Phrase(english: "Hello / Hi", spanish: "Hola", phonetic: "OH-lah"),
                Phrase(english: "Good morning", spanish: "Buenos días", phonetic: "BWEH-nohs DEE-ahs"),
                Phrase(english: "Good afternoon", spanish: "Buenas tardes", phonetic: "BWEH-nahs TAR-dehs"),
                Phrase(english: "Good night", spanish: "Buenas noches", phonetic: "BWEH-nahs NO-chehs"),
                Phrase(english: "Please", spanish: "Por favor", phonetic: "por fah-VOR"),
                Phrase(english: "Thank you", spanish: "Gracias", phonetic: "GRAH-see-ahs"),
                Phrase(english: "You're welcome", spanish: "Con gusto", phonetic: "kohn GOO-stoh"),
                Phrase(english: "Excuse me", spanish: "Disculpe", phonetic: "dees-KOOL-peh"),
                Phrase(english: "Yes / No", spanish: "Sí / No", phonetic: "see / noh"),
                Phrase(english: "I don't speak Spanish", spanish: "No hablo español", phonetic: "noh AH-bloh ehs-pah-NYOL"),
                Phrase(english: "Do you speak English?", spanish: "¿Habla inglés?", phonetic: "AH-blah een-GLEHS"),
            ]
        case .gettingAround:
            return [
                Phrase(english: "How much to go to…?", spanish: "¿Cuánto cobra para ir a…?", phonetic: "KWAHN-toh KOH-brah PAH-rah eer ah"),
                Phrase(english: "Take me to West Bay", spanish: "Lléveme a West Bay", phonetic: "YEH-veh-meh ah West Bay"),
                Phrase(english: "Stop here, please", spanish: "Pare aquí, por favor", phonetic: "PAH-reh ah-KEE por fah-VOR"),
                Phrase(english: "Is it far?", spanish: "¿Está lejos?", phonetic: "ehs-TAH LEH-hohs"),
                Phrase(english: "Where is…?", spanish: "¿Dónde está…?", phonetic: "DOHN-deh ehs-TAH"),
                Phrase(english: "Turn left / right", spanish: "Doble a la izquierda / derecha", phonetic: "DOH-bleh ah lah ees-KYEHR-dah / deh-REH-chah"),
                Phrase(english: "I need to go to the port", spanish: "Necesito ir al puerto", phonetic: "neh-seh-SEE-toh eer ahl PWEHR-toh"),
                Phrase(english: "Wait for me here", spanish: "Espéreme aquí", phonetic: "ehs-PEH-reh-meh ah-KEE"),
            ]
        case .eatingDrinking:
            return [
                Phrase(english: "A table for two, please", spanish: "Una mesa para dos, por favor", phonetic: "OO-nah MEH-sah PAH-rah dohs por fah-VOR"),
                Phrase(english: "The menu, please", spanish: "El menú, por favor", phonetic: "el meh-NOO por fah-VOR"),
                Phrase(english: "I'd like…", spanish: "Quisiera…", phonetic: "kee-SYEH-rah"),
                Phrase(english: "The check, please", spanish: "La cuenta, por favor", phonetic: "lah KWEHN-tah por fah-VOR"),
                Phrase(english: "A beer, please", spanish: "Una cerveza, por favor", phonetic: "OO-nah sehr-VEH-sah por fah-VOR"),
                Phrase(english: "Water, no ice", spanish: "Agua, sin hielo", phonetic: "AH-gwah seen YEH-loh"),
                Phrase(english: "Very delicious!", spanish: "¡Muy rico!", phonetic: "mooy REE-koh"),
                Phrase(english: "I'm allergic to…", spanish: "Soy alérgico a…", phonetic: "soy ah-LEHR-hee-koh ah"),
                Phrase(english: "Do you accept cards?", spanish: "¿Aceptan tarjeta?", phonetic: "ah-SEHP-tahn tar-HEH-tah"),
                Phrase(english: "Cash only?", spanish: "¿Solo efectivo?", phonetic: "SOH-loh eh-fehk-TEE-voh"),
            ]
        case .shopping:
            return [
                Phrase(english: "How much does this cost?", spanish: "¿Cuánto cuesta esto?", phonetic: "KWAHN-toh KWEHS-tah EHS-toh"),
                Phrase(english: "Too expensive", spanish: "Muy caro", phonetic: "mooy KAH-roh"),
                Phrase(english: "Can you lower the price?", spanish: "¿Me da un mejor precio?", phonetic: "meh dah oon meh-HOR PREH-syoh"),
                Phrase(english: "I'll take it", spanish: "Me lo llevo", phonetic: "meh loh YEH-voh"),
                Phrase(english: "Just looking, thanks", spanish: "Solo estoy viendo, gracias", phonetic: "SOH-loh ehs-TOY VYEHN-doh GRAH-syahs"),
                Phrase(english: "Do you have a smaller one?", spanish: "¿Tiene uno más pequeño?", phonetic: "TYEH-neh OO-noh mahs peh-KEH-nyoh"),
                Phrase(english: "In dollars or lempiras?", spanish: "¿En dólares o lempiras?", phonetic: "ehn DOH-lah-rehs oh lehm-PEE-rahs"),
            ]
        case .beach:
            return [
                Phrase(english: "No thank you, I'm fine", spanish: "No gracias, estoy bien", phonetic: "noh GRAH-syahs ehs-TOY byehn"),
                Phrase(english: "How much for two chairs?", spanish: "¿Cuánto por dos sillas?", phonetic: "KWAHN-toh por dohs SEE-yahs"),
                Phrase(english: "Is the water calm today?", spanish: "¿Está tranquilo el mar hoy?", phonetic: "ehs-TAH trahn-KEE-loh el mar oy"),
                Phrase(english: "Where can I snorkel?", spanish: "¿Dónde puedo hacer snorkel?", phonetic: "DOHN-deh PWEH-doh ah-SEHR snorkel"),
                Phrase(english: "Is there a current?", spanish: "¿Hay corriente?", phonetic: "eye koh-RYEHN-teh"),
                Phrase(english: "Can I rent a kayak?", spanish: "¿Puedo alquilar un kayak?", phonetic: "PWEH-doh ahl-kee-LAR oon kayak"),
                Phrase(english: "What time is sunset?", spanish: "¿A qué hora es la puesta del sol?", phonetic: "ah keh OH-rah ehs lah PWEHS-tah del sol"),
            ]
        case .wildlife:
            return [
                Phrase(english: "Don't touch the coral", spanish: "No toque el coral", phonetic: "noh TOH-keh el koh-RAHL"),
                Phrase(english: "What kind of fish is that?", spanish: "¿Qué tipo de pez es ese?", phonetic: "keh TEE-poh deh pehs ehs EH-seh"),
                Phrase(english: "Is it safe to swim here?", spanish: "¿Es seguro nadar aquí?", phonetic: "ehs seh-GOO-roh nah-DAR ah-KEE"),
                Phrase(english: "Look, a parrot!", spanish: "¡Mire, un loro!", phonetic: "MEE-reh oon LOH-roh"),
                Phrase(english: "Are there jellyfish?", spanish: "¿Hay medusas?", phonetic: "eye meh-DOO-sahs"),
                Phrase(english: "Where can I see monkeys?", spanish: "¿Dónde puedo ver monos?", phonetic: "DOHN-deh PWEH-doh vehr MOH-nohs"),
            ]
        case .slang:
            return [
                Phrase(english: "Honduran (person)", spanish: "Catracho / Catracha", phonetic: "kah-TRAH-choh / kah-TRAH-chah"),
                Phrase(english: "Wow! / Dang!", spanish: "¡Puchica!", phonetic: "poo-CHEE-kah"),
                Phrase(english: "Dude / Bro", spanish: "Maje", phonetic: "MAH-heh"),
                Phrase(english: "Cool / Awesome", spanish: "¡Qué chilero!", phonetic: "keh chee-LEH-roh"),
                Phrase(english: "Work / Job", spanish: "Chamba", phonetic: "CHAHM-bah"),
                Phrase(english: "Kid / Child", spanish: "Cipote", phonetic: "see-POH-teh"),
                Phrase(english: "Party / Hangout", spanish: "Cachimba", phonetic: "kah-CHEEM-bah"),
                Phrase(english: "Money (slang)", spanish: "Pisto", phonetic: "PEES-toh"),
                Phrase(english: "A lot / Too much", spanish: "Un vergo", phonetic: "oon VEHR-goh"),
                Phrase(english: "Snack / Street food", spanish: "Baleada", phonetic: "bah-leh-AH-dah"),
                Phrase(english: "Let's go!", spanish: "¡Vamos pues!", phonetic: "VAH-mohs pwehs"),
            ]
        }
    }
}
