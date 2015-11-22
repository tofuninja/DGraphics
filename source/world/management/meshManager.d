module world.management.meshManager;

import graphics.mesh;
import container.clist;

private struct entry
{
	Mesh mesh;
	uint ref_count;
}

struct MeshManager
{
	private entry[meshID] meshes;

	public Mesh getMesh(string s)
	{
		return getMesh(meshID(s, 0));
	}

	public Mesh getMesh(string s, uint index)
	{
		return getMesh(meshID(s, index));
	}

	public Mesh getMesh(meshID id)
	{
		entry* p = id in meshes;
		if(p == null)
		{
			// we dont have a mesh by that id, load the file by that name and recheck if we loaded the mesh, if not, then the mesh could not be found
			Mesh[] from_file = loadMeshAsset(id.name);

			foreach(m; from_file)
			{
				entry e;
				e.ref_count = 0; 
				e.mesh = m;
				meshes[m.id] = e;
				if(m.id == id) p = &(meshes[m.id]);
			}

			if(p == null)
			{
				// could not find mesh
				// TODO log error?
				return null;
			}
		}

		p.ref_count ++;
		return p.mesh;
	}

	void freeMesh(Mesh mesh)
	{
		entry* p = mesh.id in meshes;
		assert(p != null, "Trying to free a non managed mesh?");
		p.ref_count--;
		assert(p.ref_count >= 0, "Mesh ref count went negitive, free with out get?");
	}

}