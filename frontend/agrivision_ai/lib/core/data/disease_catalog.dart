/// Farmer-friendly disease encyclopedia covering all 9 crops in
/// AgriVision AI's roadmap. This is informational reference content
/// (browsable via the "All Crops" screen) — separate from the
/// on-device AI model, which currently only detects diseases for
/// Apple, Corn, Grape, Potato, and Tomato (see disease_classifier.dart).
///
/// Each entry is written for a farmer with no technical/biology
/// background: what it looks like, why it happens, what to do right
/// now, and how to prevent it next time — no jargon, no chemical
/// names without a plain-language explanation of what they're for.
/// Specific product/brand names and dosages are deliberately left out
/// since registered products and safe application rates vary by
/// region and change over time — always defer to the local
/// agriculture shop or extension office for that specific guidance.
library;

class DiseaseInfo {
  final String name;
  final String whatItLooksLike;
  final String whyItHappens;
  final String whatToDo;
  final String howToPrevent;

  const DiseaseInfo({
    required this.name,
    required this.whatItLooksLike,
    required this.whyItHappens,
    required this.whatToDo,
    required this.howToPrevent,
  });
}

class CropInfo {
  final String name;
  final bool aiSupported; // can the camera scanner currently detect this crop?
  final List<DiseaseInfo> diseases;

  const CropInfo({
    required this.name,
    required this.aiSupported,
    required this.diseases,
  });
}

const List<CropInfo> kCropDiseaseCatalog = [
  // ============ TOMATO ============
  CropInfo(
    name: 'Tomato',
    aiSupported: true,
    diseases: [
      DiseaseInfo(
        name: 'Bacterial Spot',
        whatItLooksLike: 'Small, dark, water-soaked spots on leaves, stems, and fruit — they often look greasy or wet, almost like an oil stain, and may have a thin yellow ring (halo) around them. On fruit, the spots start small but can become raised and scab-like as they age. Badly affected leaves eventually turn yellow and fall off, which weakens the whole plant over time.',
        whyItHappens: 'This spreads through water — rain splashing off an infected leaf onto a healthy one, overhead watering that wets the leaves, or even morning dew sitting on the plant for hours. It also spreads easily on your hands or tools if you touch an infected plant and then a healthy one without cleaning up in between. Warm, humid weather makes it spread much faster.',
        whatToDo: 'Pick off and remove the worst-affected leaves as soon as you notice them — don\'t leave infected leaves lying on the ground near the plant. Switch to watering at the base of the plant with a can or drip line instead of a sprinkler that wets the leaves. Try to avoid touching plants when their leaves are still wet from rain or dew, since that\'s when the bacteria spread most easily on your hands. If it keeps spreading despite this, ask your local agriculture shop about a copper-based spray, which is commonly used for bacterial diseases like this one.',
        howToPrevent: 'Start with disease-free seeds or seedlings from a trusted source — this is the single biggest prevention step, since infected seed is a common starting point. Give plants enough spacing (don\'t crowd them) so sun and air can dry the leaves quickly after rain instead of staying wet for hours. Clean your pruning tools between plants if you\'ve been handling an infected one.',
      ),
      DiseaseInfo(
        name: 'Early Blight',
        whatItLooksLike: 'Brown spots that look like a target or bullseye — rings inside rings — usually starting on the older, lower leaves near the base of the plant first. The area of leaf around each spot often turns yellow before the whole leaf eventually dries up and drops. Over a few weeks it can climb upward and affect most of the plant if untreated, and can also cause dark sunken spots on the fruit near the stem.',
        whyItHappens: 'A fungus that survives in old plant debris and in the soil from a previous season, waiting for the right conditions. It becomes active and spreads fastest in warm weather (around 24-29°C) combined with high humidity or frequent rain — splashing water carries the fungus spores from the soil up onto the lower leaves, which is why it usually starts there.',
        whatToDo: 'Remove the affected lower leaves regularly and carry them away from the field rather than leaving them on the ground, since that just feeds the problem back into the soil. Keep the plant well-fed with a balanced fertilizer, particularly enough potassium, since a healthy, well-nourished plant naturally resists this better than a stressed one. Mulching around the base of the plant with straw can help stop soil from splashing up onto the lower leaves when it rains.',
        howToPrevent: 'Rotate your planting — avoid growing tomato or potato in the exact same soil two seasons in a row, since the fungus survives in the soil between seasons. Clear away and destroy old plant debris after harvest instead of leaving it in the field or composting it nearby. Space plants generously so air can move through and dry the leaves faster after rain.',
      ),
      DiseaseInfo(
        name: 'Late Blight',
        whatItLooksLike: 'Large, dark, water-soaked patches on leaves that can spread and turn a big section of the leaf brown or black within just a day or two — this disease moves unusually fast compared to most others. In damp weather, look closely at the underside of the affected leaf for a white, slightly fuzzy growth along the edge of the dark patch. Stems can develop dark streaks too, and infected fruit gets firm, greasy-looking brown blotches. This is considered one of the most serious tomato diseases because of how quickly it can destroy an entire field.',
        whyItHappens: 'A fast-spreading, fungus-like organism (historically the same type of pathogen behind the Irish potato famine) that thrives specifically in cool, wet, humid conditions — cool nights combined with damp, cloudy days are its ideal environment. It spreads through the air over long distances on wind and rain, meaning it can jump between fields, not just plants next to each other.',
        whatToDo: 'This is the one disease on this list where speed genuinely matters — don\'t wait a few days to see if it gets worse. Remove and destroy infected leaves and, in bad cases, entire infected plants immediately, since every day of delay allows it to spread further. Go to your local agriculture shop as soon as you see the first signs and ask specifically about a fungicide suited for late blight, and follow the label instructions on timing and reapplication exactly, since a single treatment usually isn\'t enough once it has started.',
        howToPrevent: 'Avoid overhead watering altogether, especially in the evening, since wet leaves overnight is exactly what this disease needs to take hold. Give plants generous spacing so air keeps circulating and leaves dry out quickly. Pull out and destroy any volunteer potato or tomato plants growing on their own from last season\'s leftover tubers/seeds, since those can carry the disease over between seasons even if you didn\'t plant anything there deliberately.',
      ),
      DiseaseInfo(
        name: 'Leaf Mold',
        whatItLooksLike: 'Pale yellow, somewhat blotchy patches appear on the top side of the leaf first. If you flip the leaf over and look underneath directly below each yellow patch, you\'ll usually find a fuzzy, olive-green to grayish-purple coating — that fuzzy underside growth is the clearest way to tell this apart from other leaf spots. As it worsens, the yellow patches merge and the whole leaf can curl, wither, and drop.',
        whyItHappens: 'This is a humidity problem more than anything else — it thrives specifically where air isn\'t moving well and moisture builds up around the leaves, which is why it\'s especially common inside greenhouses, poly tunnels, or any densely packed planting where airflow is poor. Cooler nights with high humidity make it worse.',
        whatToDo: 'The main fix is improving airflow — prune out some of the lower and inner leaves if the plant has grown very thick and bushy, so air can move through it more freely. Cut back on humidity by watering only at the base of the plant, never over the top, and if you\'re growing under cover, open vents or increase ventilation, especially in the morning when humidity tends to be highest.',
        howToPrevent: 'Give plants more spacing right from the start so crowding doesn\'t become a problem later. If you\'re growing in a greenhouse or tunnel, make ventilation a regular habit rather than something you only think about once mold appears — open it up daily if the climate allows, particularly during humid stretches.',
      ),
      DiseaseInfo(
        name: 'Septoria Leaf Spot',
        whatItLooksLike: 'Many small, roughly circular spots appear across the leaf — each one has a dark brown edge with a pale gray or tan center, and if you look closely you can sometimes see tiny black dots inside the gray center (these are the fungus\'s spore-producing structures). It usually starts on the lower, older leaves and works its way up the plant over time, and a badly affected plant can lose most of its lower leaves.',
        whyItHappens: 'A fungus that survives in old, infected plant debris left on the ground from a previous crop, and spreads mainly through water splash — rain or overhead watering knocking spores from old debris or lower leaves up onto healthy foliage. It spreads fastest in warm, wet weather with frequent rain.',
        whatToDo: 'Pick off and dispose of the worst-affected leaves away from the field rather than leaving them to rot nearby. Switch to watering at the base of the plant instead of overhead, since wet leaves are exactly what lets this spread from leaf to leaf.',
        howToPrevent: 'Clear away old tomato plant debris thoroughly after every harvest instead of leaving it in the field over winter, since that\'s where the fungus survives to start the cycle again next season. Rotate your tomato planting to a different spot each year rather than the same patch of ground repeatedly.',
      ),
      DiseaseInfo(
        name: 'Spider Mites',
        whatItLooksLike: 'This one isn\'t a disease at all — it\'s a tiny pest. Look for very small yellow or white speckled dots scattered across the leaf, almost like the leaf has been lightly dusted or stippled. In bad infestations, you\'ll notice extremely fine, spider-web-like threads especially on the underside of the leaf and between leaves, which is a clear giveaway. Heavily affected leaves take on a dusty, bronze, or faded look and can eventually dry up.',
        whyItHappens: 'Spider mites are tiny insect-like pests that thrive in hot, dry weather, and they multiply extremely fast in those conditions — a small, unnoticed infestation can explode within a couple of weeks during a hot, dry spell. Dusty conditions and plants under drought stress are especially attractive to them.',
        whatToDo: 'A strong jet of water sprayed on the underside of the leaves can physically knock a lot of mites off and is often enough for a mild case. For a heavier infestation, neem oil or an insecticidal soap applied to the underside of the leaves (where the mites actually live) works well — always follow the label instructions for how often to reapply, since one application usually isn\'t enough to break the full mite life cycle.',
        howToPrevent: 'Keep plants consistently well-watered, especially during hot, dry spells, since drought-stressed plants attract far more mites than well-watered ones. Avoid excessive dust around the plants where possible, since dusty leaf surfaces seem to encourage mite populations to build up.',
      ),
      DiseaseInfo(
        name: 'Target Spot',
        whatItLooksLike: 'Brown spots with visible circular rings inside them — quite similar in appearance to Early Blight — but Target Spot tends to appear on leaves, stems, and fruit alike, whereas Early Blight mostly sticks to leaves. On fruit, it can cause sunken, pitted spots.',
        whyItHappens: 'A fungus that thrives in warm, humid weather and spreads through a combination of wind carrying spores and water splash moving them from plant to plant, similar to several of the other fungal leaf diseases on this list.',
        whatToDo: 'Remove the badly affected leaves as you spot them. If it\'s spreading quickly across the plant, ask your local agriculture shop about a suitable fungicide, since letting it run unchecked in warm, humid weather can let it move through a field fast.',
        howToPrevent: 'Rotate crops each season rather than replanting tomato in the same soil repeatedly, and clear away plant debris thoroughly after harvest, since — like most of the fungal diseases here — this one survives in old plant material left behind in the field.',
      ),
      DiseaseInfo(
        name: 'Tomato Mosaic Virus',
        whatItLooksLike: 'Leaves develop a blotchy, patchy pattern of light and dark green — almost like a mosaic tile pattern, which is where the name comes from. Leaves are often also curled, smaller than normal, or oddly shaped (distorted). Fruit can be smaller than usual or show uneven ripening/discoloration. Unlike most fungal diseases, there\'s no treatment that cures a plant once it\'s infected.',
        whyItHappens: 'A virus that spreads mainly through infected seed, contaminated tools, and hands — simply touching an infected plant and then a healthy one can pass it along, since the virus is extremely persistent and hard to kill on surfaces. It can also spread through handling tobacco products and then touching plants, since some strains of tobacco carry a closely related virus.',
        whatToDo: 'There\'s no cure once a plant shows symptoms, so the priority is stopping it from spreading further — remove and destroy the entire infected plant (not just the affected leaves) rather than trying to save it, since the virus is throughout the whole plant, not just the visibly affected parts. Wash your hands thoroughly and clean your tools with soap or a disinfectant after handling an infected plant, before you touch any healthy plants.',
        howToPrevent: 'Buy certified virus-free seeds from a reliable source rather than saving seed from an unknown or previously affected crop. If you or anyone working in the field uses tobacco products, wash hands thoroughly before handling plants, since the virus can survive on hands after contact with tobacco.',
      ),
      DiseaseInfo(
        name: 'Tomato Yellow Leaf Curl Virus',
        whatItLooksLike: 'Leaves curl upward at the edges (like a cup or spoon shape) and turn yellow, particularly around the leaf margins. The whole plant tends to look stunted, growing much shorter and bushier than a healthy plant, with fewer and smaller fruit. This usually shows up in young plants first and can seriously reduce how much fruit the plant ever produces.',
        whyItHappens: 'A virus that doesn\'t spread on its own — it needs to be carried by a tiny flying insect called the whitefly, which picks up the virus feeding on an infected plant and then carries it to the next plant it feeds on. Warm regions with a lot of whitefly activity see this disease much more often. Like Mosaic Virus, there is no cure once a plant is infected.',
        whatToDo: 'Remove and destroy infected plants promptly to remove them as a source the whiteflies can keep spreading from. The real priority though is getting the whitefly population under control in the area — ask your local shop about an appropriate insecticide for whiteflies, or consider yellow sticky traps, which whiteflies are strongly attracted to and get physically trapped on.',
        howToPrevent: 'If whiteflies are a known problem in your area, cover young seedlings with a fine insect-proof net during their most vulnerable early growth stage, since young plants are hit hardest. Start controlling whitefly populations early in the season before numbers build up, rather than waiting until you already see curled, yellow leaves.',
      ),
    ],
  ),

  // ============ POTATO ============
  CropInfo(
    name: 'Potato',
    aiSupported: true,
    diseases: [
      DiseaseInfo(
        name: 'Early Blight',
        whatItLooksLike: 'Dark brown spots with visible target-like rings appear on the older leaves first, with the surrounding leaf tissue often turning yellow around each spot. As it progresses, affected leaves dry up and die, and the disease works its way up the plant from the bottom over time. It generally doesn\'t affect the tubers underground directly, but a badly weakened plant produces a smaller harvest.',
        whyItHappens: 'A fungus that survives in the soil and in old plant debris left over from a previous crop, becoming active and spreading fastest in warm, humid weather — splashing rain or irrigation water carries the fungus from the soil onto the lower leaves.',
        whatToDo: 'Remove affected leaves as you notice them, and keep the plant well-nourished with a balanced fertilizer, since — as with tomato Early Blight — a healthy, well-fed plant resists this noticeably better than a stressed one.',
        howToPrevent: 'Rotate crops — avoid planting potato in soil that grew potato or tomato the previous season, since the fungus survives in that soil between seasons and picks right back up if you replant the same family of crop there.',
      ),
      DiseaseInfo(
        name: 'Late Blight',
        whatItLooksLike: 'Dark, water-soaked patches appear on leaves and stems and can spread across a large section of the plant within just a day or two — this is unusually fast compared to most other diseases. In damp weather, check the underside of an affected leaf for a white, slightly fuzzy growth along the edge of the dark patch. This disease can also travel down into the ground and rot the potato tubers themselves, sometimes without much warning above ground, which is what made it historically so devastating.',
        whyItHappens: 'A fast-moving, fungus-like organism (the same general pathogen type behind the historic Irish potato famine) that thrives in cool, damp conditions — cool nights and cloudy, humid days are its ideal environment. It spreads through the air on wind and rain across long distances, not just between neighboring plants.',
        whatToDo: 'Act immediately, without waiting — remove and destroy infected plants as soon as you spot symptoms, since every day of delay lets it spread much further given how fast this disease moves. Go to your local agriculture shop right away and ask specifically for a fungicide suited to late blight, following the label\'s reapplication schedule closely, since a single spray is usually not enough on its own.',
        howToPrevent: 'Make sure the field has good drainage, since standing water and waterlogged soil make conditions much more favorable for this disease. Avoid overhead watering, particularly in the evening. When it comes time to harvest, make sure tubers are dried and stored in a cool, dry, well-ventilated place, since an infected tuber can rot and spread the disease to healthy tubers sitting near it in storage.',
      ),
    ],
  ),

  // ============ CORN ============
  CropInfo(
    name: 'Corn',
    aiSupported: true,
    diseases: [
      DiseaseInfo(
        name: 'Common Rust',
        whatItLooksLike: 'Small, reddish-brown, slightly raised bumps scattered across both the top and underside of the leaf — they genuinely look a bit like rust forming on metal, which is where the name comes from. If you rub a finger across an affected leaf, a rusty-orange powder (the fungus\'s spores) can come off on your skin.',
        whyItHappens: 'A fungus whose spores travel long distances on the wind, and it spreads and develops fastest in cool, humid weather rather than hot conditions.',
        whatToDo: 'In most cases this is mild enough that the plant tolerates it without much impact on yield, so it often doesn\'t need direct treatment. If you\'re seeing a severe, heavy covering of rust across most leaves, ask your local agriculture shop about a suitable fungicide.',
        howToPrevent: 'If rust has been a recurring, serious problem in your fields season after season, look into rust-resistant corn varieties for future planting — this is the most effective long-term solution for a disease that spreads on the wind and is hard to control through field management alone.',
      ),
      DiseaseInfo(
        name: 'Gray Leaf Spot',
        whatItLooksLike: 'Narrow, rectangular, gray-to-brown spots that run parallel to the veins of the leaf, giving affected leaves a distinctive streaky appearance rather than round spots. In a bad case, the streaks can merge together and cause large sections of the leaf to die, significantly reducing the plant\'s ability to photosynthesize and fill out the grain.',
        whyItHappens: 'A fungus that survives in old corn debris left in the field from a previous season, and spreads fastest in warm, humid weather, especially in fields that are densely planted with poor airflow between plants.',
        whatToDo: 'Remove badly affected leaves where it\'s practical to do so on a small planting. For a serious outbreak across a larger field, ask your local agriculture shop about an appropriate fungicide, particularly if it\'s appearing early in the season while the plant still has a lot of growing left to do.',
        howToPrevent: 'Clear away old corn stalks and debris thoroughly after harvest rather than leaving them in the field, since that residue is exactly where this fungus survives between seasons. Avoid planting too densely — extra spacing lets air move through the field and dry leaves faster after rain.',
      ),
      DiseaseInfo(
        name: 'Northern Leaf Blight',
        whatItLooksLike: 'Long, grayish-green patches shaped like a cigar or canoe appear on the leaves, eventually turning tan or brown as they age and dry out. These patches can be several centimeters long and, in a bad case, merge together to affect large portions of the leaf, which reduces the plant\'s ability to fill out healthy grain.',
        whyItHappens: 'A fungus that survives in old corn crop residue left behind after harvest, spreading through both wind and rain splash carrying spores from that residue onto new growth.',
        whatToDo: 'Remove badly affected leaves early on if it\'s a small planting where that\'s practical. For larger outbreaks, ask your local agriculture shop about a suitable fungicide, ideally applied before the disease has spread through most of the plant.',
        howToPrevent: 'If this has been a repeated problem in a field, consider rotating away from corn for at least one season to break the disease cycle, since the fungus needs corn residue to survive between seasons. Clear old plant debris after harvest rather than leaving it to sit in the field over winter.',
      ),
    ],
  ),

  // ============ RICE ============
  CropInfo(
    name: 'Rice',
    aiSupported: false,
    diseases: [
      DiseaseInfo(
        name: 'Brown Spot',
        whatItLooksLike: 'Small, oval, brown spots scattered across the leaves — they often start out looking like tiny dark dots before growing into more noticeable oval spots with a slightly darker border and a lighter brown center. In more advanced cases, similar spots can appear directly on the rice grain itself, discoloring it and affecting grain quality at harvest.',
        whyItHappens: 'A fungus that becomes a much bigger problem in fields with poor soil nutrition — particularly low potassium — and in humid conditions. Nutrient-deficient, stressed plants are noticeably more susceptible than well-fed ones, which is why this disease is often described as a sign of an underlying soil fertility problem as much as a standalone disease.',
        whatToDo: 'Improve soil fertility with a balanced fertilizer program, paying particular attention to potassium levels, since correcting the underlying nutrient deficiency often does more to control this disease than anything sprayed on afterward. For active, severe outbreaks, ask your local agriculture shop about a suitable fungicide as an additional measure.',
        howToPrevent: 'Start with healthy, disease-free seed rather than saving seed from a previously affected crop. Maintain good, balanced soil nutrition throughout the growing season rather than only fertilizing once at planting, since ongoing nutrient stress is what invites this disease in.',
      ),
      DiseaseInfo(
        name: 'Leaf Blast',
        whatItLooksLike: 'Spindle-shaped or diamond-shaped spots with a gray-green center and a brown border appear on the leaves. In a bad outbreak, these spots merge together and can kill large sections of the leaf very quickly, sometimes making a field look scorched or burned from a distance.',
        whyItHappens: 'A fast-spreading fungus that\'s made worse by three specific conditions working together: high humidity, heavy nitrogen fertilizer use (excess nitrogen makes the plant tissue softer and more vulnerable), and dense planting that traps humidity around the plants and limits airflow.',
        whatToDo: 'Cut back on excess nitrogen fertilizer if you\'ve been applying heavily, since that directly feeds the problem. For an active outbreak, ask your local agriculture shop about a suitable fungicide, ideally applied as early as possible once symptoms are first noticed rather than waiting for it to spread further.',
        howToPrevent: 'If this has been a recurring issue in your area, look into blast-resistant rice varieties for future seasons — this is one of the most effective long-term solutions available. Avoid over-fertilizing with nitrogen, and follow a balanced fertilizer program instead.',
      ),
      DiseaseInfo(
        name: 'Neck Blast',
        whatItLooksLike: 'A grayish-brown rot forms at the "neck" of the rice panicle — the point where the grain-bearing head meets the main stem. This weak, rotted point can cause the entire grain head above it to die, turning white or empty since it can no longer receive water and nutrients from the plant. This is often the most damaging stage of blast disease because it directly destroys the harvestable grain rather than just leaf tissue.',
        whyItHappens: 'Caused by the same fungus as Leaf Blast, but attacking a different, more critical part of the plant — the grain head itself rather than the leaves — which is why it tends to cause more direct yield loss than the leaf form of the disease.',
        whatToDo: 'If caught early, right as the panicle is emerging, ask your local agriculture shop about a fungicide specifically timed for that panicle stage, since timing matters a great deal here. Once a panicle is already severely affected and turning white/empty, it usually can\'t be saved — the focus shifts to protecting the remaining healthy panicles in the field.',
        howToPrevent: 'Use blast-resistant rice varieties where available, particularly if this has been a repeated problem in your area. Avoid excess nitrogen fertilizer, especially in the weeks approaching flowering, since that\'s when the plant is most vulnerable to this particular stage of the disease.',
      ),
    ],
  ),

  // ============ GRAPE ============
  CropInfo(
    name: 'Grape',
    aiSupported: true,
    diseases: [
      DiseaseInfo(
        name: 'Black Rot',
        whatItLooksLike: 'Small, brown, circular spots appear on the leaves, often with a darker ring around the edge. On the fruit, the effect is much more dramatic — infected grapes shrivel up completely into hard, black, wrinkled "mummies" that stay attached to the vine, which is one of the clearest signs of this disease.',
        whyItHappens: 'A fungus that survives through the off-season in old mummified fruit and infected wood left on or near the vine, then becomes active again and spreads to new growth once warm, wet spring weather arrives.',
        whatToDo: 'Remove and destroy every mummified fruit and infected leaf you can find — don\'t leave them hanging on the vine or lying on the ground nearby, since they\'re actively re-infecting new growth each season. Prune the vine to open it up and improve airflow, which helps leaves and fruit dry faster after rain.',
        howToPrevent: 'If black rot has been a repeated, serious problem, ask your local agriculture shop about starting a fungicide program early in the season — timing this correctly around bud break and early growth stages matters a lot for how effective it is, so ask specifically about the right timing for your region.',
      ),
      DiseaseInfo(
        name: 'Esca (Black Measles)',
        whatItLooksLike: 'A distinctive striped, tiger-like pattern of yellow and brown/reddish discoloration appears between the veins of the leaf (the veins themselves usually stay green, which is a helpful way to identify this specific disease). Small, dark, sunken spots can also appear on the berries, sometimes giving them a measle-like speckled look. This disease lives inside the older wood of the vine, and there is no full cure once it\'s established there.',
        whyItHappens: 'A fungus that enters the vine through pruning wounds or other injuries to the wood, then slowly colonizes the inside of the older trunk and branches over months or years before symptoms become visible above ground.',
        whatToDo: 'Prune out and remove any wood you can identify as infected, cutting back into clean, healthy wood beyond the visibly affected area. Avoid pruning during wet weather specifically, since fresh pruning wounds are far more likely to become infected when it\'s damp.',
        howToPrevent: 'Do your pruning during dry weather whenever possible, since dry conditions give wounds time to seal over before the fungus has a good chance to enter. For larger pruning cuts, ask locally whether sealing the cut with a wound-sealing product is recommended in your area, since practices vary by region.',
      ),
      DiseaseInfo(
        name: 'Leaf Blight',
        whatItLooksLike: 'Dark brown, angular-edged spots appear on the leaves — the "angular" shape (following the leaf\'s vein pattern rather than being perfectly round) is a useful way to tell this apart from other grape leaf diseases. These spots can join together as the disease progresses, causing affected leaves to dry up and drop from the vine earlier than they should.',
        whyItHappens: 'A fungus that spreads mainly through water splash — rain or irrigation water carrying spores from infected, fallen leaves and other debris on the ground back up onto healthy foliage.',
        whatToDo: 'Clear away fallen infected leaves from around the base of the vine regularly rather than letting them accumulate. If it\'s actively spreading, ask your local agriculture shop about a copper-based treatment, which is commonly used for this type of fungal leaf disease.',
        howToPrevent: 'Clear fallen leaves and other plant debris from around the vine thoroughly at the end of each season rather than leaving them to sit through winter, since that debris is exactly where the fungus survives to start the next cycle.',
      ),
    ],
  ),

  // ============ APPLE ============
  CropInfo(
    name: 'Apple',
    aiSupported: true,
    diseases: [
      DiseaseInfo(
        name: 'Apple Scab',
        whatItLooksLike: 'Olive-green to black, slightly velvety-textured spots appear on both leaves and fruit. On fruit specifically, these spots can cause the skin to crack open or develop a rough, corky texture as the fruit continues to grow around the damaged area, which affects how the fruit looks even though it\'s often still edible.',
        whyItHappens: 'A fungus that survives the winter hidden in fallen leaves on the ground beneath the tree, then becomes active again and releases spores into the air during wet spring weather right around the time new leaves and blossoms are emerging — which is exactly when the tree is most vulnerable.',
        whatToDo: 'Rake up and remove fallen leaves from underneath and around the tree in autumn — this single step removes the fungus\'s main overwintering spot and dramatically reduces how much scab shows up the following spring. For an active infection, ask your local agriculture shop about a fungicide timed specifically for early spring, right as buds are starting to open.',
        howToPrevent: 'Make raking up fallen leaves every single autumn a non-negotiable yearly habit — this is genuinely the biggest single thing you can do to reduce scab pressure the following year, more effective than most sprays applied afterward.',
      ),
      DiseaseInfo(
        name: 'Black Rot',
        whatItLooksLike: 'Spots with a purple border appear on the leaves, while the fruit develops brown, rotten patches that often show faint concentric rings as they enlarge — similar to a target pattern. Dead or dying wood on the tree is frequently where you\'ll trace the source of an outbreak back to.',
        whyItHappens: 'A fungus that enters the tree through wounds, cracks, or existing dead wood, then spreads to nearby healthy tissue during warm, wet weather.',
        whatToDo: 'Prune out and remove dead or visibly diseased branches, cutting back into healthy wood. Also remove any shriveled, mummified fruit left hanging on the tree or lying underneath it, since — like grape black rot — that old fruit keeps re-infecting the tree each season if left in place.',
        howToPrevent: 'Prune the tree regularly as routine maintenance to remove dead wood before it becomes a large problem, since dead wood is specifically where this fungus establishes itself and spreads from.',
      ),
      DiseaseInfo(
        name: 'Cedar Apple Rust',
        whatItLooksLike: 'Bright orange-yellow spots appear on the upper side of the leaves, and in some cases you\'ll notice small raised bumps within those spots. Unlike most fungal diseases, this one has a genuinely unusual life cycle — it needs to travel back and forth between an apple tree and a nearby cedar or juniper tree to complete its full cycle each year.',
        whyItHappens: 'A fungus with a two-host life cycle: spores from a nearby cedar/juniper tree infect the apple tree in spring, and later in the season spores from the apple tree travel back to infect the cedar/juniper — it genuinely can\'t complete its cycle without both types of tree present nearby.',
        whatToDo: 'If this is a recurring issue, ask your local agriculture shop about a fungicide timed for spring, right around the period when spores are traveling from nearby cedar/juniper trees to the apple tree.',
        howToPrevent: 'Where practical, avoid planting apple trees very close to cedar or juniper trees, since removing one half of the disease\'s required host pair from the immediate area can meaningfully reduce how often this shows up.',
      ),
    ],
  ),

  // ============ SUGARCANE ============
  CropInfo(
    name: 'Sugarcane',
    aiSupported: false,
    diseases: [
      DiseaseInfo(
        name: 'Red Rot',
        whatItLooksLike: 'The clearest sign is internal — cut open the cane stalk and look inside: a healthy cane is white/cream colored inside, but a red-rot-affected cane shows reddish discoloration with white patches running through it, often with a distinct sour, fermented smell. Above ground, leaves may turn a yellow-red color and dry out, and the cane can develop a hollow, dried, or shrunken feel in badly affected sections.',
        whyItHappens: 'A serious fungal disease that spreads primarily through infected "seed cane" — the pieces of cane cut from a previous crop and used for planting the next one — as well as through infected soil. Using seed cane from an already-infected field is the single most common way this disease gets introduced to a new planting.',
        whatToDo: 'Remove and completely destroy infected plants — this disease spreads easily and aggressively through infected planting material, so don\'t try to save or work around infected cane. Critically, never use cane cut from an infected field as seed cane for your next planting, even if some parts of that cane look okay, since the infection can be present without being visible everywhere.',
        howToPrevent: 'Always source healthy, disease-free seed cane from a trusted, certified supplier rather than reusing cane from your own or a neighboring field of uncertain health status. If red rot has been a repeated problem in a particular field, rotate to a different crop for at least one season to help break the disease cycle in the soil.',
      ),
      DiseaseInfo(
        name: 'Bacterial Blight',
        whatItLooksLike: 'Long, white-to-yellow streaks run along the length of the leaves, following the natural direction of the leaf veins. Over time these streaks can dry out and cause the leaf tips to turn brown and die back.',
        whyItHappens: 'A bacterial disease that spreads through infected planting material (similar to Red Rot), rain splash carrying bacteria from plant to plant, and contaminated tools that pick up the bacteria from an infected plant and carry it to a healthy one.',
        whatToDo: 'Remove badly affected plants to reduce the source of further spread in the field. Clean and disinfect your cutting tools between working on different fields or different sections of a field, since contaminated tools are a real way this spreads that\'s easy to overlook.',
        howToPrevent: 'Use certified disease-free seed cane from a trusted source, same as with Red Rot prevention. Avoid working in the field — cutting, handling plants, etc. — when the leaves are still wet, since that\'s when the bacteria transfer most easily between plants and onto tools.',
      ),
    ],
  ),

  // ============ WHEAT ============
  CropInfo(
    name: 'Wheat',
    aiSupported: false,
    diseases: [
      DiseaseInfo(
        name: 'Brown Rust',
        whatItLooksLike: 'Small, round, orange-brown, slightly raised bumps are scattered across the leaf surface, mostly on the upper side. If you rub a finger over an affected leaf, an orange-brown powder (the fungus\'s spores) often comes off onto your skin, similar to corn rust.',
        whyItHappens: 'A fungus whose spores spread through the air on the wind, and it\'s favored by mild temperatures combined with humid conditions rather than very hot or very dry weather.',
        whatToDo: 'For an active outbreak, ask your local agriculture shop about a suitable fungicide — catching it early in the season, before it has spread through most of the crop, gives you the best results.',
        howToPrevent: 'If brown rust has been a recurring problem in your area season after season, look into rust-resistant wheat varieties for future planting, since that\'s the most reliable long-term way to reduce a wind-spread disease like this.',
      ),
      DiseaseInfo(
        name: 'Yellow Rust',
        whatItLooksLike: 'Bright yellow-orange, powdery stripes run along the leaf, closely following the direction of the leaf veins — the striped pattern (rather than scattered bumps) is what distinguishes this from Brown Rust. It can also appear on the stem in severe cases.',
        whyItHappens: 'A fungus that spreads especially fast in cool, humid weather and, unlike many other crop diseases, can travel very long distances through the air — sometimes affecting fields far from where an outbreak originally started.',
        whatToDo: 'Act quickly if you spot it early in the season — ask your local agriculture shop about a fungicide as soon as possible, since this disease can spread through and significantly reduce yield across a field faster than many others on this list.',
        howToPrevent: 'Plant rust-resistant wheat varieties where they\'re available, particularly if this has been a repeated issue in your region. If yellow rust is known to be common in your area, avoid sowing unusually early in the season, since early-sown crops can be more exposed to the disease\'s peak spread period.',
      ),
    ],
  ),

  // ============ CITRUS ============
  CropInfo(
    name: 'Citrus',
    aiSupported: false,
    diseases: [
      DiseaseInfo(
        name: 'Black Spot',
        whatItLooksLike: 'Small, dark spots with grayish centers appear on the fruit skin. These mostly affect appearance rather than the inside of the fruit — the flesh underneath is usually still perfectly fine to eat even when the skin looks affected, though the fruit becomes harder to sell if appearance matters to your buyers.',
        whyItHappens: 'A fungus that survives in fallen, infected leaves on the ground beneath the tree and spreads more actively during warm, wet weather.',
        whatToDo: 'Clear away fallen leaves and old fruit from underneath the tree regularly. If it\'s a recurring problem, ask your local agriculture shop about a suitable fungicide.',
        howToPrevent: 'Keep the ground under and around the tree clear of fallen leaves and old fruit as an ongoing habit, since that\'s specifically where the fungus survives between seasons to reinfect the tree.',
      ),
      DiseaseInfo(
        name: 'Canker',
        whatItLooksLike: 'Raised, rough, corky brown spots appear on leaves, stems, and fruit, often surrounded by a distinct yellow ring (halo) — that yellow halo is a helpful way to recognize canker specifically. In severe, wet, windy conditions this can spread very rapidly across a tree or even between neighboring trees.',
        whyItHappens: 'A bacterial disease that spreads through wind-driven rain (rain blown sideways by wind, which pushes bacteria into leaf surfaces more forcefully than regular rainfall), contaminated tools, and infected plant material moved between trees or orchards.',
        whatToDo: 'Remove and destroy badly infected branches to reduce the source of ongoing spread. Disinfect your pruning tools between working on different trees, since contaminated tools are a genuine way this disease travels that\'s easy to underestimate.',
        howToPrevent: 'If your area is prone to strong, wind-driven rain, consider planting windbreaks (rows of taller trees or shrubs) to reduce how forcefully rain hits your citrus trees. Always use disease-free planting material when establishing new trees.',
      ),
      DiseaseInfo(
        name: 'Scab',
        whatItLooksLike: 'Raised, wart-like, rough, scabby spots form on both leaves and fruit skin. Similar to Black Spot, the fruit is generally still perfectly edible inside despite looking rough and less attractive on the outside.',
        whyItHappens: 'A fungus that\'s favored by wet weather specifically during the tree\'s new leaf and young fruit growth stage in spring, which is when the plant tissue is most vulnerable to infection.',
        whatToDo: 'Prune the tree to improve airflow through the canopy, which helps new growth dry faster after rain. If this has been a repeated issue, ask your local agriculture shop about a fungicide timed specifically for the wet season.',
        howToPrevent: 'Avoid overhead watering specifically during the young fruit growth stage in spring, since that\'s the tree\'s most vulnerable window for this disease.',
      ),
      DiseaseInfo(
        name: 'Greening (Huanglongbing)',
        whatItLooksLike: 'Blotchy yellow patches appear on leaves, and — this is a distinctive giveaway — the pattern often looks different on each side of the very same leaf, which is unusual compared to most other leaf diseases. Fruit becomes small, oddly lopsided in shape, and stays partly green even when it should be fully ripe, often with a notably bitter taste. This is considered one of the most serious citrus diseases in the world, and it has caused severe damage to citrus industries in multiple countries.',
        whyItHappens: 'A bacterial disease spread by a tiny flying insect called the citrus psyllid, which picks up the bacteria feeding on an infected tree and carries it to the next tree it feeds on — similar in concept to how whiteflies spread Tomato Yellow Leaf Curl Virus. There is no cure once a tree is infected, and infection is usually a slow, progressive decline over months to years.',
        whatToDo: 'There is genuinely no cure once symptoms appear — infected trees usually need to be removed entirely to protect the health of nearby, still-healthy trees, since an infected tree continues to serve as a source the psyllid insect can keep spreading from. Because this disease is taken extremely seriously by agriculture authorities in most citrus-growing regions, contact your local agriculture extension office as soon as you suspect it, both for guidance and because there may be mandatory reporting or removal requirements in your area.',
        howToPrevent: 'Focus on controlling the psyllid insect that spreads the disease, following guidance from your local agriculture extension office on appropriate methods for your region. Only plant certified disease-free trees from a reputable, verified nursery — this is a disease where prevention through clean planting material matters enormously, since there\'s no way to treat it after the fact.',
      ),
      DiseaseInfo(
        name: 'Melanose',
        whatItLooksLike: 'Small, raised, dark brown to black, rough spots appear on both the fruit skin and leaves — sometimes these spots line up in a tear-streak pattern, following the path where water has run down the fruit or leaf surface.',
        whyItHappens: 'A fungus that lives specifically in dead twigs and branches within the tree itself (rather than in fallen debris on the ground, which is where several other citrus diseases on this list survive), spreading to nearby young, healthy growth when rain washes spores from the dead wood onto fresh tissue.',
        whatToDo: 'Prune out and remove dead twigs and branches from the tree — since that dead wood is specifically where the fungus lives and spreads from, removing it directly addresses the source rather than just treating symptoms.',
        howToPrevent: 'Make regularly pruning dead wood out of the tree an ongoing habit rather than a one-time fix — this alone significantly reduces melanose over time since it removes the fungus\'s home base within the tree.',
      ),
    ],
  ),
];