#include "asm_program.h"

asection* bfd_sections( bfd *abfd) {
  return abfd->sections;
}

asection* bfd_next_section( asection *s) {
  return s->next;
}


//        bfd_get_section_contents(abfd, section, data, 0, datasize);

bfd* asmir_get_bfd(asm_program_t *p) {
  return p->abfd;
}

address_t bfd_section_get_vma(asection *s) {
  return s->vma;
}

bfd_size_type bfd_section_get_size(asection *s) {
  return s->size;
}

const char* bfd_section_get_name(asection *s) {
  return s->name;
}
