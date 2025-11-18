# StickyToDo - Credits & Acknowledgments

**Project**: StickyToDo - Plain Text Task Management with Visual Boards
**Date**: 2025-11-17 to 2025-11-18
**Status**: Phase 1 Core Implementation Complete

---

## Design & Development

### Primary Contributors

**Design & Implementation**
- **Claude** (Anthropic) - AI Assistant
  - Complete design phase via Socratic dialogue
  - Full implementation of core models and data layer
  - Framework prototyping (both AppKit and SwiftUI)
  - Integration architecture
  - Comprehensive documentation
  - Test suite development

**Project Concept**
- Original concept: Plain text GTD task manager with visual boards
- Innovation: Boards-as-filters approach (no data duplication)
- Vision: User ownership of data through plain text

---

## Inspiration & Influences

### Productivity Methodology

**Getting Things Done (GTD)**
- **Author**: David Allen
- **Book**: "Getting Things Done: The Art of Stress-Free Productivity"
- **Influence**: Core task management methodology
  - Inbox processing workflow
  - Next Actions perspective
  - Contexts and Projects organization
  - Weekly Review concept
  - Five status types (Inbox, Next Action, Waiting, Someday, Completed)

**Resources**:
- [Getting Things Done](https://gettingthingsdone.com/)
- David Allen Company

### Application Design Inspiration

**OmniFocus**
- **Developer**: The Omni Group
- **Platform**: macOS, iOS, iPadOS
- **Inspiration**:
  - Perspective system (smart filtered views)
  - Keyboard-first navigation
  - Review mode
  - Professional GTD implementation
  - Inspector panel design

**Things**
- **Developer**: Cultured Code
- **Platform**: macOS, iOS, iPadOS
- **Inspiration**:
  - Natural language task parsing
  - Clean, minimal UI design
  - Quick entry workflow
  - Polish and attention to detail
  - Evening/Today/Upcoming organization

**Miro**
- **Developer**: Miro
- **Platform**: Web, Desktop, Mobile
- **Inspiration**:
  - Infinite canvas concept
  - Sticky note visual metaphor
  - Freeform spatial organization
  - Collaboration on visual boards
  - Pan/zoom interactions

**Asana**
- **Developer**: Asana, Inc.
- **Platform**: Web, Desktop, Mobile
- **Inspiration**:
  - Board view / List view toggle
  - Task metadata system
  - Project and team organization

**TaskPaper**
- **Developer**: Hog Bay Software (Jesse Grosjean)
- **Platform**: macOS, iOS
- **Inspiration**:
  - Plain text task format
  - Tag-based organization
  - Human-readable file format
  - Future-proof data storage
  - Version control friendly

**Obsidian**
- **Developer**: Obsidian
- **Platform**: Cross-platform
- **Inspiration**:
  - Markdown-based storage
  - Local-first data approach
  - File system integration
  - Plain text philosophy

---

## Open Source Libraries & Technologies

### Direct Dependencies

**Yams** - YAML Parser for Swift
- **Repository**: https://github.com/jpsim/Yams
- **Author**: JP Simard and contributors
- **License**: MIT License
- **Version**: 5.0.0+
- **Usage**: YAML frontmatter parsing and generation
- **Why**: Robust, well-maintained, pure Swift implementation

**Acknowledgment**: Yams is the foundation of StickyToDo's data layer, enabling seamless conversion between Swift models and YAML frontmatter.

### Apple Frameworks

**Swift** - Programming Language
- **Developer**: Apple Inc. and open source contributors
- **Version**: 5.9+
- **License**: Apache 2.0
- **Usage**: Primary development language

**SwiftUI** - UI Framework
- **Developer**: Apple Inc.
- **Usage**: Modern declarative UI (70% of app)
- **Acknowledgment**: Enables rapid development of standard UI components

**AppKit** - UI Framework
- **Developer**: Apple Inc.
- **Usage**: High-performance canvas (30% of app)
- **Acknowledgment**: Provides the performance needed for smooth canvas interactions

**Foundation** - Core Framework
- **Developer**: Apple Inc.
- **Usage**: Core utilities, file I/O, date handling, etc.

**Combine** - Reactive Framework
- **Developer**: Apple Inc.
- **Usage**: Reactive data flow, @Published properties, data binding

**CoreServices** - System Framework
- **Developer**: Apple Inc.
- **Usage**: FSEvents for file system monitoring

**XCTest** - Testing Framework
- **Developer**: Apple Inc.
- **Usage**: Unit and integration testing

---

## Development Methodology

### Design Process

**Socratic Dialogue**
- Iterative questioning to refine requirements
- Exploration of edge cases and trade-offs
- Decision documentation with rationale

**YAGNI Principle** (You Aren't Gonna Need It)
- Focus on MVP (Phase 1) only
- Defer complex features to Phase 2
- Avoid over-engineering
- Build what's needed, when it's needed

**Incremental Development**
- Design phase → Models → Data layer → Prototypes → Integration
- Each layer validated before moving to next
- Comprehensive testing at each stage

### Architecture Patterns

**MVVM** (Model-View-ViewModel)
- **Origin**: Microsoft (2005)
- **Usage**: Data binding pattern for UI
- **SwiftUI Integration**: Natural fit with @Published properties

**Repository Pattern**
- **Usage**: TaskStore and BoardStore abstract data access
- **Benefit**: Clean separation between business logic and persistence

**Protocol-Oriented Programming**
- **Swift Philosophy**: Protocols over inheritance
- **Usage**: AppCoordinator protocol for both frameworks
- **Benefit**: Flexibility and testability

**Coordinator Pattern**
- **Usage**: Navigation and app flow management
- **Benefit**: Decouples view controllers from navigation logic

---

## Documentation & Resources

### Technical References

**Apple Developer Documentation**
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [FSEvents Programming Guide](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/)
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Combine Framework](https://developer.apple.com/documentation/combine/)

**Community Resources**
- [Hacking with Swift](https://www.hackingwithswift.com/) - Paul Hudson
- [Swift Forums](https://forums.swift.org/)
- [NSHipster](https://nshipstered.com/)
- [Stack Overflow](https://stackoverflow.com/)

### Design Resources

**Plain Text Philosophy**
- [The Plain Text Project](https://plaintextproject.online/)
- [Plain Text Productivity](https://plaintext-productivity.net/)
- Todo.txt format and community

**GTD Resources**
- [David Allen Company](https://gettingthingsdone.com/)
- GTD methodology documentation
- Community forums and discussions

---

## Tools & Software

### Development Tools

**Xcode**
- **Developer**: Apple Inc.
- **Version**: 15.0+
- **Usage**: Primary IDE for Swift/macOS development
- **Features Used**: Interface Builder, Instruments, Debugger, Previews

**Git**
- **Usage**: Version control
- **Platform**: GitHub/GitLab/etc.

**Instruments**
- **Developer**: Apple Inc.
- **Usage**: Performance profiling and debugging

### Design Tools

**SF Symbols**
- **Developer**: Apple Inc.
- **Usage**: System icons for UI
- **License**: Free for Apple platform development

**Markdown**
- **Format**: Lightweight markup language
- **Usage**: Documentation and task file format
- **Specification**: CommonMark

---

## Community & Ecosystem

### Swift Community

**Acknowledgment**: The Swift community provides incredible resources, libraries, and support that make projects like StickyToDo possible.

**Key Contributors**:
- Swift evolution proposals
- Open source library developers
- Tutorial and blog writers
- Stack Overflow contributors
- Forum moderators and helpers

### Task Management Community

**Acknowledgment**: The productivity and task management community has pioneered concepts and workflows that inform StickyToDo's design.

**Key Influences**:
- GTD practitioners and forums
- Plain text productivity advocates
- Indie productivity app developers
- User communities of similar tools

---

## Special Thanks

### Conceptual Contributions

**Plain Text Movement**
- Advocates for future-proof, portable data formats
- Champions of user data ownership
- Proponents of version control for everything

**Indie Developer Community**
- Building thoughtful, user-focused software
- Sharing knowledge and best practices
- Inspiring quality and craftsmanship

**macOS Developer Community**
- Keeping AppKit knowledge alive
- Exploring hybrid AppKit/SwiftUI approaches
- Sharing performance optimization techniques

---

## License Information

### StickyToDo

**License**: MIT License (recommended)

```
MIT License

Copyright (c) 2025 StickyToDo Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Dependencies

**Yams** - MIT License
- Compatible with StickyToDo's MIT license
- Allows commercial use, modification, distribution

---

## Development Process Acknowledgment

### AI-Assisted Development

**Claude by Anthropic**
- **Model**: Claude (Anthropic)
- **Role**: Primary design and implementation assistant
- **Contributions**:
  - System design and architecture
  - Code implementation (models, data layer, prototypes)
  - Test suite development
  - Comprehensive documentation
  - Framework analysis and comparison

**Methodology**:
- Collaborative design through dialogue
- Iterative refinement based on requirements
- Test-driven development
- Emphasis on documentation and maintainability
- Following best practices and patterns

**Human Oversight**:
- Concept and requirements definition
- Design decisions and trade-off evaluation
- Quality assurance and validation
- Final integration and deployment

---

## Future Acknowledgments

As StickyToDo grows and evolves, we anticipate contributions from:

### Beta Testers
- Early adopters providing feedback
- Bug reporters helping improve quality
- Feature requesters guiding development

### Contributors
- Code contributors (if open source)
- Documentation writers
- Translators (if localization added)
- Designer collaborators

### Community
- Users sharing workflows
- Content creators making tutorials
- Productivity enthusiasts spreading the word

---

## Citation & Attribution

### Using StickyToDo in Research or Publications

If you use StickyToDo in academic research or publications, please cite:

```
StickyToDo: Plain Text Task Management with Visual Boards
Version 1.0, 2025
Available at: [URL when published]
```

### Derivative Works

If you create derivative works or adaptations:

1. Respect the MIT License terms
2. Acknowledge the original StickyToDo project
3. Note modifications made
4. Consider contributing back improvements

---

## Contact & Contributions

### Reporting Issues

- Check existing documentation
- Search closed issues
- Provide reproduction steps
- Include system information

### Suggesting Features

- Explain the use case
- Describe expected behavior
- Consider if it fits Phase 1, 2, or 3
- Acknowledge it may be deferred

### Contributing Code

- Read DEVELOPMENT.md
- Follow coding standards
- Include tests
- Update documentation
- Submit pull request

---

## Thank You

To everyone who:
- Contributed ideas and inspiration
- Built the tools and libraries we use
- Shared knowledge and best practices
- Supported indie software development
- Believes in plain text and user data ownership

**Your collective work makes projects like StickyToDo possible.**

---

## Version History

**v1.0** (In Development)
- Initial design and core implementation
- AppKit and SwiftUI prototypes
- Data layer and models
- Comprehensive documentation

---

## Final Note

StickyToDo stands on the shoulders of giants:

- **Productivity pioneers** who refined task management methodologies
- **Application designers** who explored new interaction paradigms
- **Open source developers** who shared their work freely
- **Platform creators** who provided powerful frameworks
- **The community** who inspires, teaches, and supports

Thank you all.

---

**Document Version**: 1.0
**Last Updated**: 2025-11-18
**Status**: Complete

---

*"We are all standing on the shoulders of those who came before us."*

**Your tasks. Your format. Your control.**
