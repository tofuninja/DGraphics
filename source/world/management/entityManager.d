module world.entityManager;
import world.entity;
import container.clist;
class EntityManager
{
	private CList!Entity entity_list;

	public auto entities()
	{
		return entity_list.Range();
	}
}