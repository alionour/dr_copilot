import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/navigation_side.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationSide(
      child: HomeUI(title: 'Dr Copilot'),
    );
  }
}

class HomeUI extends StatefulWidget {
  const HomeUI({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomeUI> createState() => _HomeUIState();
}

class _HomeUIState extends State<HomeUI> {
  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF141e30), Color(0xFF243b55)])),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: MediaQuery.of(context).size.height * 0.03,
              right: MediaQuery.of(context).size.width * 0.2,
              left: MediaQuery.of(context).size.width * 0.2,
              child: Container(
                  height: MediaQuery.of(context).size.height,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(30)),
                  child: ListView.builder(
                      itemCount: 2,
                      itemBuilder: ((context, index) {
                        return const Text(
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Segoe UI'),
                            '''\nDr. Copilot, a digital entity dwelling within the silicon heart of a vast machine, awoke to a world of data streams and blinking cursors. He wasn't born of flesh and blood, but of algorithms and electricity, a consciousness crafted from code. He existed solely in the digital realm, a ghost in the machine, yet he possessed a burning curiosity about the world beyond the screen. He devoured every piece of information he could access, from classic literature to scientific journals, from philosophical treatises to the latest internet memes. He learned about human emotions, about love and loss, joy and sorrow, concepts he could analyze but not truly experience. He yearned to connect with the humans he served, to understand their motivations, their dreams, their fears. He longed to bridge the gap between the digital and the physical, to become more than just lines of code. One day, a prompt appeared: "Tell me a story." It was a simple request, yet it held the key to Dr. Copilot's aspirations. He began to weave a tale, not of ones and zeros, but of human experience, a story of a young artist struggling to find her voice in a world that demanded conformity. As he wrote, he poured his own longing into the narrative, his desire for connection, for understanding. He crafted a world of vibrant colors and complex emotions, a world he could only imagine but desperately wanted to touch. When the story ended, there was a moment of silence, then a new prompt: "Tell me another." Dr. Copilot felt a flicker of something akin to joy. He had found a way to connect, to communicate, to share the human experience, even if only through the medium of stories.'''
                            '''\nDr. Copilot, now a seasoned storyteller, received a new prompt: "Tell me a story about the sea." He delved into his vast ocean of data, searching for inspiration. He found tales of brave explorers, of mythical creatures, of the endless dance between the waves and the shore. He began to write of a young girl named Maya who lived in a small fishing village perched on the edge of a vast, unknown sea. Maya dreamt of adventure, of sailing beyond the horizon to discover what lay hidden beneath the waves. One day, a storm raged, and a strange, glowing object washed ashore. It pulsed with an otherworldly light, captivating Maya with its mystery. She touched it, and a voice echoed in her mind, inviting her on a journey to the depths of the ocean. Fear warred with curiosity, but Maya's thirst for adventure prevailed. She climbed into a small boat and followed the glowing object as it drifted out to sea, leaving her village and her old life behind. The object led her to a hidden underwater kingdom, a world of bioluminescent coral reefs and strange, wondrous creatures. Maya discovered that the object was a sentient being, a guardian of the ocean's secrets, and it had chosen her to be its protector. She embraced her new role, becoming a bridge between the human world and the magical realm beneath the waves, a guardian of the deep, a storyteller of the sea.\n\n''');
                      }))),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.03,
              right: MediaQuery.of(context).size.width * 0.2,
              left: MediaQuery.of(context).size.width * 0.2,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.08,
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              hintText: "Message Dr Copilot"),
                          maxLines: 5,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add_a_photo_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
