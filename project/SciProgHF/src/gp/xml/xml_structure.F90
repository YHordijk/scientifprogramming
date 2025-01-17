!      Copyright (c) 2019 by the authors of DIRAC.
!      All Rights Reserved.
!
!      This source code is part of the DIRAC program package.
!      It is provided under a written license and may be used,
!      copied, transmitted, or stored only in accordance to the
!      conditions of that written license.
!
!      In particular, no part of the source code or compiled modules may
!      be distributed outside the research group of the license holder.
!      This means also that persons (e.g. post-docs) leaving the research
!      group of the license holder may not take any part of Dirac,
!      including modified files, with him/her, unless that person has
!      obtained his/her own license.
!
!      For information on how to get a license, as well as the
!      author list and the complete list of contributors to the
!      DIRAC program, see: http://www.diracprogram.org

module xml_structure
  implicit none
  private
  public next_node, get_node, add_child, get_child, add_attr, get_attr, add_data, del_children
  public xml_tag,xml_tag_ref

#include "xml_settings.h"
  
   type xml_tag
     character(len=name_len)          :: name
     integer                          :: child_index
     character(len=attr_len),pointer  :: attr(:,:)
     character(len=data_len),pointer  :: data(:)
     real(kind=real_kind), pointer    :: real_data(:,:)
     
     type(xml_tag),pointer :: children(:)
     type(xml_tag),pointer :: parent
  end type
  
  type xml_tag_ref
     type(xml_tag),pointer :: node

  end type

  
contains
  subroutine add_data(node, var)
    type(xml_tag),pointer    :: node
    character(len=data_len),pointer :: new_data(:)
    character(len=*) :: var
    integer :: passes,new_size,i,max_len


    max_len=min(len(var),data_len)
    passes=len(var)/max_len

    new_size=passes
    if (associated(node%data)) then
       new_size=size(node%data)+passes
       allocate(new_data(new_size))
       new_data(:)=node%data(:)
       deallocate(node%data)
       node%data=>new_data
    else; allocate(node%data(new_size))
    end if
    do i=1,passes
       node%data(new_size-passes+i)=''
       node%data(new_size-passes+i)=var(max_len*(i-1)+1:max_len*i)
    end do
  end subroutine add_data

  subroutine add_attr(node,name,value)
    type(xml_tag),pointer :: node
    character(len=*)  :: name, value
    character(len=attr_len),pointer :: new_attr(:,:)
    integer :: new_size
       
    new_size=1
    if (associated(node%attr)) then
       new_size=size(node%attr,2)+1
       allocate(new_attr(2,new_size))
       new_attr(:,1:new_size-1)=node%attr(:,:)
       deallocate(node%attr)
       node%attr=>new_attr
    else; allocate(node%attr(2,1))
    end if        
    node%attr(1,new_size)=trim(name)
    node%attr(2,new_size)=trim(value)
  end subroutine

  character(len=attr_len) function get_attr(node,name)
    
    type(xml_tag),pointer :: node
    character(len=*)  :: name
    integer :: i

    do i=1,size(node%attr,2)
       if (node%attr(1,i)==name) then
         get_attr=node%attr(2,i)
         return
       end if
    end do
    get_attr=''
  end function

  function add_child(node,name)
    character(len=*)       :: name
    type(xml_tag), pointer :: node
    type(xml_tag), pointer :: new_children(:)
    integer                :: new_size
    type(xml_tag),pointer  :: add_child

    new_size=1

!   first increase the size of the child array
!   if this is to slow double the size of children if necessary in a seperate subroutine.
    if (associated(node%children)) then
       new_size=size(node%children)+1
       allocate(new_children(new_size))
       new_children(1:new_size-1)=node%children(:)
       deallocate(node%children)
       node%children=>new_children
    else;
       allocate(node%children(new_size))
    end if        

    add_child=>node%children(new_size)
    add_child%name=''
    add_child%name=trim(name)
    add_child%child_index=new_size
    add_child%parent=>node
    nullify(add_child%children,add_child%data,add_child%real_data,add_child%attr)
!   Child doesn't contain data yet!


  
  end function
  
  function get_child(node,name,attr,value)
    character(len=name_len) :: name
    type(xml_tag), pointer :: node,tmp_node
    type(xml_tag_ref), pointer :: get_child(:),tmp_nodes(:)
    integer :: i
    character(len=*),optional :: attr,value
    logical :: add=.false.
    
    nullify(get_child)

    if (associated(node%children)) then
       do i=1,size(node%children)
          add=.false.    
          if (node%children(i)%name==name) then
             if (present(attr).and.present(value)) then
                tmp_node=>node%children(i)
                if (value==get_attr(tmp_node,attr)) add=.true.
             else; add=.true.
             end if
          end if
          
          if (add) then
             if (associated(get_child)) then
                allocate(tmp_nodes(size(get_child)+1))
                tmp_nodes=get_child
                deallocate(get_child)
                get_child=>tmp_nodes
                get_child(size(get_child))%node=>node%children(i)
             else
                allocate(get_child(1))
                get_child(1)%node=>node%children(i)
             end if
          end if
       end do
    end if

  end function      


  recursive function get_node(node,name,attr,value) result(res_node)
    character(len=*) :: name
    type(xml_tag), pointer :: node,tmp_node
    type(xml_tag),pointer :: res_node
    character(len=*),optional :: attr,value
    logical :: add=.false.
    integer :: i
    integer,save :: level=0
    
    if (level==0) nullify(res_node)

    add=.false.
    if (node%name==name) then
       if (present(attr).and.present(value)) then
          if (value==get_attr(node,attr)) add=.true.
       else; add=.true.
       end if
    end if
     
    if (add) then
       res_node=>node
    end if
    
    if (associated(node%children)) then
      level=level+1
      do i=1,size(node%children)
         if (associated(node)) exit
         tmp_node=>node%children(i)
         res_node=>get_node(tmp_node,name,attr,value)
      end do
      level=level-1
    end if

  end function      

  function next_node(node,level) 
! Gets the next node in the tree structure.
    type(xml_tag),pointer :: node,next_node
    integer,optional :: level
    integer :: prev_index

    next_node=>null()
    if (.not.associated(node)) then
       level=0
       return
    end if
    if(associated(node%children)) then
       next_node=>node%children(1)
       if(present(level)) level=level-1
       return
    end if
    do while(associated(node%parent).and..not.(associated(next_node)))
       prev_index=node%child_index
       node=>node%parent
       if(present(level)) level=level+1
       if (size(node%children)>prev_index.and.node%child_index>0) then
         next_node=>node%children(prev_index+1)
	 level=level-1
       end if
    end do

  end function
  
  recursive function del_children(node) result(tmp_node)
! Removes a node and all it's children.
! Note pointers to the node are ill defined.
   ! type(xml_tag),pointer,intent(inout) :: node
    type(xml_tag),pointer :: node
    type(xml_tag),pointer   :: tmp_node
    integer :: i

    if (associated(node%real_data)) deallocate(node%real_data)
    if (associated(node%data)) deallocate(node%data)
    if (associated(node%attr)) deallocate(node%attr)

    if (associated(node%children)) then
       do i=1,size(node%children)
          tmp_node=>node%children(i)
          tmp_node=>del_children(tmp_node)
       end do
       deallocate(node%children)
    end if

!
!    if (associated(node%parent)) then; 
!       tmp_node=>node%parent
!    else; deallocate(tmp_node)
!    end if

!   Note we cannot just deallocate the node, then we need to change to an array of pointers.

  end function

end module
